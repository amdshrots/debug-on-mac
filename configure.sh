#!/usr/bin/env bash
# configure.sh VNC_USER_PASSWORD VNC_PASSWORD 

# 1) Disable Spotlight indexing for performance
sudo mdutil -i off -a

# 2) Create a dedicated VNC user
sudo dscl . -create /Users/vncuser
sudo dscl . -create /Users/vncuser UserShell /bin/bash
sudo dscl . -create /Users/vncuser RealName "VNC User"
sudo dscl . -create /Users/vncuser UniqueID 1001
sudo dscl . -create /Users/vncuser PrimaryGroupID 80
sudo dscl . -create /Users/vncuser NFSHomeDirectory /Users/vncuser
sudo dscl . -passwd /Users/vncuser "$1"
sudo createhomedir -c -u vncuser > /dev/null

# 3) Enable Apple Remote Desktop (ARD) / VNC
ARD="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart"
sudo "$ARD" -configure -allowAccessFor -allUsers -privs -all
sudo "$ARD" -configure -clientopts -setvnclegacy -vnclegacy yes

# 4) Hash & write the VNC password (legacy VNC file)
echo "$2" | perl -we \
  'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA" }
   $_ = <>;
   chomp;
   s/^(.{8}).*/$1/;
   @p = unpack "C*", $_;
   foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) };
   print "\n"' \
  | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

# 5) Restart and activate ARD agent
sudo "$ARD" -restart -agent -console
sudo "$ARD" -activate

# 6) Grant TCC (Privacy) rights so VNC can capture & control the screen
#    (prevents the “black screen” on macOS ≥12.1)
TCC_DB="/Library/Application Support/com.apple.TCC/TCC.db"
TIMESTAMP=$(date +%s)
# allow screen capture
sudo sqlite3 "$TCC_DB" \
  "INSERT OR REPLACE INTO access VALUES('kTCCServiceScreenCapture','com.apple.screensharing.agent',0,2,4,1,NULL,NULL,0,'UNUSED',NULL,0,$TIMESTAMP);"
# allow posting events (mouse/keyboard control)
sudo sqlite3 "$TCC_DB" \
  "INSERT OR REPLACE INTO access VALUES('kTCCServicePostEvent','com.apple.screensharing.agent',0,2,4,1,NULL,NULL,0,'UNUSED',NULL,0,$TIMESTAMP);"

ssh -p 443 -R0:localhost:5900 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 gtcxZbEfnfR+tcp@us.free.pinggy.io &>/dev/null &
