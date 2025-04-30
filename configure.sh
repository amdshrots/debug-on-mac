#!/bin/bash
# configure.sh <VNC_USER_PASSWORD> <VNC_PASSWORD> [<ZROK_TOKEN>]

# Disable Spotlight to avoid issues (optional).
sudo mdutil -i off -a

# Create a new admin user 'vncuser' with the given password.
sudo dscl . -create /Users/vncuser
sudo dscl . -create /Users/vncuser UserShell /bin/bash
sudo dscl . -create /Users/vncuser RealName "VNC User"
sudo dscl . -create /Users/vncuser UniqueID 1001
sudo dscl . -create /Users/vncuser PrimaryGroupID 80
sudo dscl . -create /Users/vncuser NFSHomeDirectory /Users/vncuser
sudo dscl . -passwd /Users/vncuser "$1"
sudo dscl . -passwd /Users/vncuser "$1"
sudo createhomedir -c -u vncuser > /dev/null

# Enable Remote Management (Apple Remote Desktop) for all users.
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -activate -configure -allowAccessFor -allUsers -privs -all -restart -agent

# Allow “Anyone may request permission to control screen” and legacy VNC.
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -configure -clientopts -setreqperm -reqperm yes
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -configure -clientopts -setvnclegacy -vnclegacy yes

# Set the VNC password (hashed) for “screen sharing”:
echo "$2" | perl -we 'BEGIN { @k = unpack "C*", pack "H*", 
  "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8}).*/$1/;
  @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' \
  | sudo tee /Library/Preferences/com.apple.VNCSettings.txt >/dev/null

# Restart the Remote Management agent to apply changes.
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -restart -agent -console

ssh -p 443 -R0:localhost:5900 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 gtcxZbEfnfR+tcp@free.pinggy.io &
