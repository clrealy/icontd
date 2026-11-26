#!/usr/bin/env bash
# icontd ISO builder — copies Arch's official releng profile, overlays icontd stuff, builds.
# Run on Arch as root:  sudo ./build.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
RELENG="/usr/share/archiso/configs/releng"
WORK="$HERE/work"
PROFILE="$WORK/profile"
OUT="$HERE/out"

[[ $EUID -eq 0 ]] || { echo "run as root (sudo ./build.sh)"; exit 1; }
command -v mkarchiso >/dev/null || { echo "install archiso first: pacman -S archiso"; exit 1; }
[[ -d $RELENG ]] || { echo "releng profile not found at $RELENG"; exit 1; }

echo ">> fresh profile from releng"
rm -rf "$WORK"
mkdir -p "$PROFILE" "$OUT"
cp -r "$RELENG/." "$PROFILE/"

echo ">> rebranding profiledef.sh"
sed -i \
  -e 's/^iso_name=.*/iso_name="icontd"/' \
  -e 's/^iso_label=.*/iso_label="ICONTD_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"/' \
  -e 's|^iso_publisher=.*|iso_publisher="icontd <https://github.com/clrealy>"|' \
  -e 's/^iso_application=.*/iso_application="icontd Live\/Install Medium"/' \
  "$PROFILE/profiledef.sh"

echo ">> marking icontd tools executable"
sed -i 's|^file_permissions=(|file_permissions=(\n  ["/usr/bin/icontd-install"]="0:0:755"\n  ["/usr/bin/icontd"]="0:0:755"|' "$PROFILE/profiledef.sh"

echo ">> adding icontd packages"
grep -vE '^\s*(#|$)' "$HERE/overlay/packages.extra" >> "$PROFILE/packages.x86_64"
sort -u "$PROFILE/packages.x86_64" -o "$PROFILE/packages.x86_64"

echo ">> overlaying airootfs"
cp -r "$HERE/overlay/airootfs/." "$PROFILE/airootfs/"

echo ">> building (this takes a min)"
mkarchiso -v -w "$WORK/build" -o "$OUT" "$PROFILE"

echo ">> done! ISO is in $OUT"
