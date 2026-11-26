# shellcheck shell=bash disable=SC2034
# icontd shared helpers — sourced by icontd-install and icontd

ICONTD_CONFIG=${ICONTD_CONFIG:-/etc/icontd/config.itd}

# GURT CLI subcommands — change here if GURT's syntax differs
GURT_INSTALLER="https://gurtproject.org/install.sh"
GURT_INSTALL=(install)
GURT_REMOVE=(remove)
GURT_UPDATE=(upgrade)
GURT_GUI_PKG="gurt-app"

# itd_get KEY  -> value (last one wins), trimmed
itd_get() {
  { grep -E "^[[:space:]]*$1[[:space:]]*=" "$ICONTD_CONFIG" || true; } \
    | tail -1 | cut -d= -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}
# itd_list KEY -> one item per line
itd_list() {
  itd_get "$1" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | { grep -v '^$' || true; }
}
itd_true() { [[ $(itd_get "$1") =~ ^(yes|true|1|on)$ ]]; }

de_pkgs() {
  case "$1" in
    plasma|kde) echo "plasma-meta konsole dolphin sddm" ;;
    gnome)      echo "gnome gdm" ;;
    xfce)       echo "xfce4 xfce4-goodies lightdm lightdm-gtk-greeter" ;;
    cinnamon)   echo "cinnamon lightdm lightdm-gtk-greeter" ;;
    hyprland)   echo "hyprland kitty sddm" ;;
    ""|none)    echo "" ;;
    *)          echo "$1" ;;
  esac
}
de_dm() {
  case "$1" in
    plasma|kde|hyprland) echo sddm ;;
    gnome) echo gdm ;;
    xfce|cinnamon) echo lightdm ;;
    *) echo "" ;;
  esac
}

# every pacman package config.itd asks for (incl. ones implied by de/shell/kernel)
itd_desired_pkgs() {
  local kernel shell de
  kernel=$(itd_get kernel); shell=$(itd_get shell); de=$(itd_get de)
  {
    echo "${kernel:-linux}"
    [[ ${shell:-zsh} != bash ]] && echo "${shell:-zsh}"
    # shellcheck disable=SC2046
    printf '%s\n' $(de_pkgs "$de")
    [[ -n $de && $de != none ]] && echo libnotify
    [[ -n $(itd_get aurpackages) ]] && echo base-devel
    [[ -n $(itd_get flatpaks) ]] && echo flatpak
    [[ -n $(itd_get dotfiles) ]] && echo rsync
    itd_list packages
  } | { grep -v '^$' || true; } | sort -u
}
itd_desired_services() {
  { itd_list services; de_dm "$(itd_get de)"; } | { grep -v '^$' || true; } | sort -u
}
itd_desired_gurt() {
  { itd_list gurt; itd_true gurt_gui && echo "$GURT_GUI_PKG"; } | { grep -v '^$' || true; } | sort -u
}
