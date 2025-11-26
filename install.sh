#!/bin/bash
# Deluge headless install script by Rig0
# Installs Deluge Daemon and Web-UI, Adjusts permissions to play nice with Servarr stack, Edits services to comply with permissions & pre configures download location.

usr=$1 # username to add to deluge group (optional argument)
delugeUsr="debian-deluged" # the user the deluge pkg creates and uses

# Bash styling
BLUE='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # no color
ST="\n${YELLOW}----------------------------------------------------------------------\n\n"
SB="\n----------------------------------------------------------------------\n\n${NC}"
delay=2 # delay in seconds after showing step

# If arguemnt passed, Check that the user exists
if [ $# -ge 1 ]; then
    if ! id "$usr" &>/dev/null; then
        echo "User '$usr' does not exist. Run script without a user or specify an existing user."
        exit
    fi
fi

printf "$ST Updating OS & Installing Deluge \n $SB"
sleep $delay

apt update && apt dist-upgrade -y
apt install deluged deluge-web -y


printf "$ST Configuring Deluge user and group permissions \n $SB"
sleep $delay

# Check if media group exists
if getent group "media" > /dev/null 2>&1; then
    echo "Group 'media' already exists. Skipping step"
else
    groupadd media
    echo "Created 'media' group"
fi

# Add deluge user to media group
usermod -aG media $delugeUsr
echo "Added '$delugeUsr' to the 'media' group"

# Add our user to deluge and media group
if [ $# -ge 1 ]; then
    usermod -aG media $usr
    usermod -aG $delugeUsr $usr
    echo "Added '$usr' to the 'media' group"
    echo "Added '$usr' to the $delugeUsr group"
fi


printf "$ST Configuring Deluge download folder \n $SB"
sleep $delay

# Creating download folders
if [ ! -d "/mnt/deluge" ]; then
    mkdir /mnt/deluge
    echo "Created download folder /mnt/deluge"
else
    echo "Download folder /mnt/deluge already exists. Skipping step."
fi

# Setting permssions that play nice with servarr stack
chmod 774 /mnt/deluge
chown -R $delugeUsr:media /mnt/deluge
echo "Adjusted download folder permissions"


printf "$ST Editing service files with correct permissions \n $SB"
sleep $delay

#stop services
systemctl stop deluged
systemctl stop deluge-web
echo "Stopped services"

# Edit the init.d script
sed -i '/^MASK=/s/0027/0002/' "/etc/init.d/deluged" 
sed -i '/^USER=/a GROUP=media' "/etc/init.d/deluged"
echo "Edited /etc/init.d/deluged"

# Edit the daemon service
daemonService='/lib/systemd/system/deluged.service'
if [ -f $daemonService ]; then
    sed -i '/^UMask=/s/007/002/' $daemonService
    sed -i '/^Group=/s/debian-deluged/media/' $daemonService
    echo "Edited $daemonService"
fi
# Edit the web service
webService='/lib/systemd/system/deluge-web.service'
if [ -f $webService ]; then
    sed -i '/^UMask=/s/007/002/' $webService
    sed -i '/^Group=/s/debian-deluged/media/' $webService
    echo "Edited $webService"
fi


printf "$ST Changing default download location in deluge config file \n $SB"
sleep $delay

# Change the default download location
sed -i 's#"download_location": "/var/lib/deluged/Downloads"#"download_location": "/mnt/deluge"#' "/var/lib/deluged/config/core.conf"
sed -i 's#"move_completed_path": "/var/lib/deluged/Downloads"#"move_completed_path": "/mnt/deluge"#' "/var/lib/deluged/config/core.conf"
sed -i 's#"torrentfiles_location": "/var/lib/deluged/Downloads"#"torrentfiles_location": "/mnt/deluge"#' "/var/lib/deluged/config/core.conf"
echo "Edited config file"


printf "$ST Starting daemon service \n $SB"
sleep $delay

# reload the system services daemon
systemctl daemon-reload

# Starting daemon service
systemctl start deluged
systemctl status deluged --no-pager


printf "$ST Starting web service \n $SB"
sleep $delay

# Starting web service
systemctl start deluge-web
systemctl status deluge-web --no-pager

# Check if UFW is installed
echo "Checking for ufw"
if command -v ufw > /dev/null 2>&1; then
    # Check if UFW is enabled
    if sudo ufw status | grep -q "Status: active"; then
        ufw allow 8112/tcp
        echo "Opened delude web ui port 8112"
    fi
fi

# Sending notification is pushover is installed
if [ -f /usr/bin/pushover ]; then
    pushover "Deluge Setup Complete"
fi

printf "\n${BLUE}----------------------------------------------------------------------\n\n"
printf "Setup Complete! \n$SB"