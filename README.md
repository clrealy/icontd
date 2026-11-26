# icontd 

Declarative Arch. Your whole system lives in one readable file: `/etc/icontd/config.itd`.
Edit it, run `sudo icontd apply`, and the system matches it.

```ini
hostname=icontd
timezone=America/New_York
shell=zsh
de=plasma
packages=git, neovim, firefox, fastfetch, openssh
aurpackages=fetch-git
flatpaks=
gurt=
gurt_gui=no
dotfiles=
services=NetworkManager, sshd
```

## Build the ISO (on Arch)

    sudo pacman -S archiso
    sudo ./build.sh

The ISO lands in `out/`. CI builds it on every push to `main` and attaches it to GitHub releases.

## Install

Boot the ISO and run `icontd-install`. It's a TUI that:

1. lets you edit config.itd
2. asks for a disk (wiped!), your user, root password, and the `icontd` user's password
3. installs everything config.itd declares: pacman pkgs, AUR, GURT, flatpaks, dotfiles, services
4. sets up GRUB (UEFI or BIOS), zsh w a starter `.zshrc`, branding + red dot fastfetch

## Using it

    sudo icontd diff      # what would change
    sudo icontd apply     # make it so
    sudo icontd upgrade   # update everything, then apply
    icontd edit           # open config.itd

Removing something from config.itd and applying **uninstalls it**, but only things icontd installed itself
(tracked in `/var/lib/icontd/managed/`), never the base system.

## Packages, declared

Yes yes, I know we're arch-based, but we killed pacman. Apologies.
## icontd-guard 🤡

Every change to config.itd is backed up to `/var/lib/icontd/config.itd.bak`. Delete config.itd and what happens is for YOU to find out!

The system is **not** immutable: root works, everything outside the package rules is normal Arch.

## Test in a VM (do this before real hardware)

    sudo pacman -S qemu-full edk2-ovmf
    qemu-img create -f qcow2 icontd-test.qcow2 30G

    # UEFI
    cp /usr/share/edk2/x64/OVMF_VARS.4m.fd ovmf_vars.fd
    qemu-system-x86_64 -enable-kvm -cpu host -m 4G -smp 4 \
      -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
      -drive if=pflash,format=raw,file=ovmf_vars.fd \
      -drive file=icontd-test.qcow2,if=virtio \
      -cdrom out/icontd-*.iso -boot order=d

    # BIOS: same thing without the two pflash lines

After installing, boot without `-cdrom` and check:

- [ ] GRUB says icontd, system boots, login works
- [ ] `fastfetch` shows the red dot + `OS: icontd`
- [ ] `pacman -S x` / `gurt install x` / `flatpak install x` → command not found
- [ ] `su - icontd` then `sudo pacman -Syu` works
- [ ] add a package to config.itd → `sudo icontd diff` shows it → `sudo icontd apply` installs it
- [ ] remove it again → apply uninstalls it
- [ ] `sudo rm /etc/icontd/config.itd` → roast + config comes back
- [ ] Discover / GNOME Software aren't there

## Layout

- `build.sh` — copies Arch's releng profile, rebrands it, adds packages + files, runs mkarchiso
- `overlay/packages.extra` — extra live ISO packages
- `overlay/airootfs/` — files on the live ISO (the installer copies what the installed system needs)
  - `/usr/bin/icontd`, `/usr/bin/icontd-install`, `/usr/lib/icontd/common.sh`
  - `/usr/share/icontd/guard/`, `/usr/share/icontd/pkgtools/`, `/usr/share/icontd/fastfetch/`
  - `/etc/icontd/config.itd`, `/etc/os-release`, `/etc/xdg/fastfetch/config.jsonc`
- `branding-src/` — original logo

## Brand

- red `#D50000` (the dot) · white `#FFFFFF` · dark `#161616`

## Known gaps

- AUR packages whose deps are also AUR-only won't build
- GURT removal uses `gurt remove` (guessed) — edit `GURT_*` in `/usr/lib/icontd/common.sh` if the CLI differs
- Per-user flatpak installs from random GUI apps can install still (idk why tho)
- dotfiles are only cloned at install time
