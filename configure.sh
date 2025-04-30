#!/bin/bash
# configure.sh <VNC_USER_PASSWORD> <VNC_PASSWORD> <NGROK_AUTH_TOKEN>

# 1. Create a new admin user for VNC
USER=vncuser
PASSWORD=2009
PASSWORD2=2222
sudo dscl . -create /Users/$USER
sudo dscl . -create /Users/$USER UserShell /bin/bash
sudo dscl . -create /Users/$USER RealName "VNC User"
sudo dscl . -create /Users/$USER UniqueID 1001
sudo dscl . -create /Users/$USER PrimaryGroupID 80
sudo dscl . -create /Users/$USER NFSHomeDirectory /Users/$USER
sudo dscl . -passwd /Users/$USER "$PASSWORD"
sudo createhomedir -c -u $USER > /dev/null

# 2. Enable Remote Management (Apple Remote Desktop) for all users
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
     -configure -allowAccessFor -allUsers -privs -all
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
     -configure -clientopts -setvnclegacy -vnclegacy yes
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
     -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
     -activate

# 3. Auto-login the new user (so the desktop session starts automatically)
# This requires macOS Ventura+ (sysadminctl supports -autologin)&#8203;:contentReference[oaicite:12]{index=12}.
sudo sysadminctl -autologin set -userName $USER -password "$PASSWORD"

# 4. Disable Spotlight indexing (optional performance tweak)
sudo mdutil -i off -a

# 5. Set the VNC viewer password (128-bit hashed)
VNC_HASH="1734516E8BA8C5E2FF1C39567390ADCA"
echo "$PASSWORD2" | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "'"$VNC_HASH"'"}; \
                     $_ = <>; chomp; s/^(.{8}).*/$1/; \
                     @p = unpack "C*", $_; \
                     foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' \
     | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

# 6. Start Pinggy for port tunneling
ssh -p 443 -R0:localhost:5900 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 gtcxZbEfnfR+tcp@us.free.pinggy.io &

echo "VNC setup complete. Connect using the displayed ngrok address."
