#!/bin/bash

# Update and install dependencies
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y git build-essential cmake openssl libssl-dev pkg-config curl wget ufw

# Set variables for RustDesk installation
INSTALL_DIR="/opt/rustdesk-server"
HBBS_PORT=21115
HBBR_PORT=21116
HBBS_RELAY_PORT=21119

# Create the installation directory
sudo mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone RustDesk server repository
git clone --depth=1 https://github.com/rustdesk/rustdesk-server.git .
git submodule update --init --recursive

# Build hbbs and hbbr binaries
mkdir -p build && cd build
cmake ..
make -j$(nproc)

# Copy binaries to the installation directory
sudo cp hbbs hbbr /usr/local/bin/

# Configure the firewall to allow required ports
sudo ufw allow "$HBBS_PORT/tcp"
sudo ufw allow "$HBBR_PORT/tcp"
sudo ufw allow "$HBBS_RELAY_PORT/tcp"
sudo ufw allow "$HBBS_RELAY_PORT/udp"
sudo ufw reload

# Create systemd service for hbbs
echo "[Unit]
Description=RustDesk ID Server (hbbs)
After=network.target

[Service]
ExecStart=/usr/local/bin/hbbs
Restart=always
User=root
WorkingDirectory=$INSTALL_DIR
[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/hbbs.service

# Create systemd service for hbbr
echo "[Unit]
Description=RustDesk Relay Server (hbbr)
After=network.target

[Service]
ExecStart=/usr/local/bin/hbbr
Restart=always
User=root
WorkingDirectory=$INSTALL_DIR
[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/hbbr.service

# Reload systemd and enable services
sudo systemctl daemon-reload
sudo systemctl enable hbbs
sudo systemctl enable hbbr

# Start RustDesk services
sudo systemctl start hbbs
sudo systemctl start hbbr

# Check the status of RustDesk services
sudo systemctl status hbbs
sudo systemctl status hbbr

echo "Installation complete! Configure your RustDesk clients with the IP of this server."
