#!/bin/bash
set -e

# Create the 'vncuser' account if it doesn't exist, and set its password
if ! dscl . -read /Users/vncuser &>/dev/null; then
  echo "Creating vncuser with UID 501"
  sudo sysadminctl -addUser vncuser -fullName "VNC User" -password 2009 -admin
fi
echo "Setting vncuser password to 2009"
sudo dscl . -passwd /Users/vncuser 2009

# Disable fast user switching login screen (optional)
sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool false
sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser vncuser

# Enable Remote Management (Apple ARD) and VNC with password 2222
echo "Enabling Remote Management and VNC access"
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -activate -configure -access -on -privs -all -users vncuser \
  -clientopts -setvnclegacy yes \
  -clientopts -setvncpw -vncpw 2222 \
  -restart -agent -console

# Disable display sleep and disable screensaver password
echo "Preventing display sleep"
sudo pmset -a displaysleep 0
sudo defaults write /Library/Preferences/com.apple.screensaver askForPassword -int 0

# Keep the session alive (caffeinate prevents idle sleep)
caffeinate -dimsu &>/dev/null &

echo "Configuration complete. VNC password is '2222', user 'vncuser' pwd '2009'."
