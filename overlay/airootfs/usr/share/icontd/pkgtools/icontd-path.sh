# only the icontd user gets pacman + gurt in PATH
if [ "$(id -un)" = "icontd" ]; then
  PATH="/usr/lib/icontd/bin:$PATH"
  export PATH
fi
