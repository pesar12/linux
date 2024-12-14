#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed."
    read -p "Press Enter to install Docker..."
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

# Function to install Chromium
install_chromium() {
    if docker ps -a | grep -q chromium; then
        echo "Chromium is already installed."
    else
        read -p "Enter username for Chromium : " USERNAME
        read -sp "Enter password for Chromium : " PASSWORD
        echo
        echo "Installing Chromium..."
        docker run -d \
            --name=chromium \
            --security-opt seccomp=unconfined `#optional` \
            -e PUID=1000 \
            -e PGID=1000 \
            -e TZ=Etc/UTC \
            -e CUSTOM_USER=$USERNAME \
            -e PASSWORD=$PASSWORD \
            -e CHROME_CLI=https://www.youtube.com/@IR_TECH/ `#optional` \
            -p 3010:3000 \
            -p 3011:1001 \
            -v /root/chromium/config:/config \
            --shm-size="1gb" \
            --restart unless-stopped \
            lscr.io/linuxserver/chromium:latest
        echo "------------------------------------------------------------------------------------------------"
        echo "Chromium installed successfully."
        IP=$(hostname -I | awk '{print $1}')
        echo " "
        echo "Use browser with http://$IP:3010"
    fi
}

# Function to uninstall Chromium
uninstall_chromium() {
    if docker ps -a | grep -q chromium; then
        echo "Uninstalling Chromium..."
        docker stop chromium
        docker rm chromium
        echo "Chromium uninstalled."
    else
        echo "Chromium is not installed."
    fi
}

# Function to install Firefox (supports multiple instances)
install_firefox() {
    read -p "Enter container name for Firefox (e.g. firefox1): " CONTAINER_NAME

    # Check if container name already exists
    if docker ps -a --format '{{.Names}}' | grep -wq "$CONTAINER_NAME"; then
        echo "A container with the name $CONTAINER_NAME already exists. Please choose a different name."
        exit 1
    fi

    read -p "Enter username for Firefox : " USERNAME
    read -sp "Enter password for Firefox : " PASSWORD
    echo
    read -p "Enter host port for Firefox web interface (default: 4010): " WEB_PORT
    WEB_PORT=${WEB_PORT:-4010} # if empty, default to 4010
    read -p "Enter host port for Firefox VNC (default: 4011): " VNC_PORT
    VNC_PORT=${VNC_PORT:-4011} # if empty, default to 4011

    echo "Installing Firefox with container name '$CONTAINER_NAME'..."
    docker run -d \
        --name="$CONTAINER_NAME" \
        --security-opt seccomp=unconfined \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ=Etc/UTC \
        -e CUSTOM_USER=$USERNAME \
        -e PASSWORD=$PASSWORD \
        -p $WEB_PORT:3000 \
        -p $VNC_PORT:3001 \
        -v /root/firefox/${CONTAINER_NAME}-config:/config \
        --shm-size="1gb" \
        --restart unless-stopped \
        lscr.io/linuxserver/firefox:latest

    echo "------------------------------------------------------------------------------------------------"
    echo "Firefox installed successfully as container '$CONTAINER_NAME'."
    IP=$(hostname -I | awk '{print $1}')
    echo " "
    echo "Use browser with http://$IP:$WEB_PORT"
}

# Function to uninstall Firefox (ask for container name)
uninstall_firefox() {
    read -p "Enter the Firefox container name you want to uninstall: " CONTAINER_NAME

    if docker ps -a --format '{{.Names}}' | grep -wq "$CONTAINER_NAME"; then
        echo "Uninstalling Firefox container '$CONTAINER_NAME'..."
        docker stop "$CONTAINER_NAME"
        docker rm "$CONTAINER_NAME"
        echo "Firefox container '$CONTAINER_NAME' uninstalled."
    else
        echo "No Firefox container named '$CONTAINER_NAME' found."
    fi
}

# Display the menu
echo "Select an option:"
echo "1) Install Chromium"
echo "2) Uninstall Chromium"
echo "3) Install Firefox"
echo "4) Install Firefox 2"
echo "5) Uninstall Firefox"
echo "6) Exit"
read -p "Please choose : " choice

case $choice in
    1) install_chromium ;;
    2) uninstall_chromium ;;
    3) install_firefox ;;
    4) install_firefox ;; # این مورد هم همان تابع نصب فایرفاکس را فراخوانی می‌کند
    5) uninstall_firefox ;;
    6) exit ;;
    *) echo "Invalid choice. Please select a valid option." ;;
esac
