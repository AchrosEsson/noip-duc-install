#!/bin/bash

# Copyright (c) 2024 Manuel Hampel
# This script is provided under the MIT License.
# See the LICENSE file for details.

# Automation script for downloading, installing, and configuring No-IP DUC with architecture detection and seamless credential management, including easy updates

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Please run with sudo or as root user."
  exit 1
fi

# Step 1: Determine system architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH_SUFFIX="amd64"
        ;;
    aarch64)
        ARCH_SUFFIX="arm64"
        ;;
    armv7l)
        ARCH_SUFFIX="armhf"
        ;;
    *)
        echo -e "Unsupported architecture: $ARCH\nPlease consider a manual build or check out our docker-image."
        exit 1
        ;;
esac

# Step 2: Download the No-IP DUC package if needed
if [ ! -f "noip-duc-latest.tar.gz" ]; then
    echo "Downloading No-IP DUC..."
    wget --content-disposition https://www.noip.com/download/linux/latest -O noip-duc-latest.tar.gz
    echo "Extracting the archive..."
    tar xf noip-duc-latest.tar.gz
fi

# Extract the version number from the extracted directory name dynamically
VERSION=$(find . -type d -name "noip-duc_*" | head -n 1)

# Step 3: Install the selected package based on architecture if it's not installed
if ! dpkg -l | grep -q "noip-duc"; then
    echo "Installing No-IP DUC for $ARCH..."

    # Prüfen, ob die .deb-Datei existiert
    DEB_PACKAGE=$(find "$VERSION"/binaries -name "noip-duc_*_${ARCH_SUFFIX}.deb")
    if [ -n "$DEB_PACKAGE" ]; then
        DEB_PACKAGE=$(realpath "$DEB_PACKAGE")  # Absoluten Pfad ermitteln
        chmod 644 "$DEB_PACKAGE"
        cd "$VERSION"/binaries
        apt install "$DEB_PACKAGE"
    else
        echo "No suitable .deb package found for architecture $ARCH_SUFFIX."
        exit 1
    fi
fi

# Ensure /etc/default directory exists
if [ ! -d "/etc/default" ]; then
  echo "Creating /etc/default directory..."
  mkdir -p /etc/default
fi

# Delete the existing configuration file if it exists
if [ -f "/etc/default/noip-duc" ]; then
    echo
    read -p "Existing configuration found. Do you want to update your credentials? (y/n): " update_response
    if [[ "$update_response" == "y" || "$update_response" == "Y" ]]; then
        echo "Updating configuration..."
        rm -f /etc/default/noip-duc
    else
        echo "Configuration update canceled."
        exit 0
    fi
fi

# Step: Prompt the user for DDNS credentials
echo -e "\nPlease provide the DDNS credentials for No-IP DUC."
echo -e "If you haven't already, visit https://my.noip.com/dynamic-dns to create or manage your DDNS keys and hostnames.\n"
echo "Remember to click on 'Create DDNS Key' or 'Modify DDNS Key' to generate the required values."
echo -e "You can group hostnames together under the 'DDNS Keys / Groups' tab to have multiple hostnames updated at once.\n"

read -p "Enter DDNS Key username: " ddns_username
read -sp "Enter DDNS Key password: " ddns_password
echo

# Create or overwrite the /etc/default/noip-duc file with the new credentials
echo -e "\nCreating configuration file..."
cat <<EOL > /etc/default/noip-duc
NOIP_USERNAME=$ddns_username
NOIP_PASSWORD=$ddns_password
NOIP_HOSTNAMES=all.ddnskey.com
EOL

echo "Configuration complete. The credentials have been saved to /etc/default/noip-duc."

# Step: Start the noip-duc service
echo -e "\nStarting the noip-duc service..."
systemctl restart noip-duc.service

# Function to check if the service has updated successfully
check_update_status() {
  echo -e "\nChecking for update status..."
  while true; do
    # Check for the success message in the journal log
    if journalctl -u noip-duc.service | tail -n 4 | grep -q "update successful"; then
      echo "DDNS update successful!"
      break
    fi
    
    # Check for any errors related to incorrect credentials
    if journalctl -u noip-duc.service | tail -n 4 | grep -q "update failed; Incorrect credentials"; then
      echo -e "\nERROR: Incorrect DDNS credentials. Please check your username and password."
      return 1
    fi

    # Sleep before checking again to avoid excessive CPU usage
    sleep 5
  done
}

# Check initial status once the service is started
check_update_status

# If incorrect credentials were detected, ask for new credentials and restart the process
while [ $? -eq 1 ]; do
  echo -e "\nPlease provide the DDNS credentials again."
  read -p "Enter DDNS Key username: " ddns_username
  read -sp "Enter DDNS Key password: " ddns_password
  echo

  # Update the /etc/default/noip-duc file
  echo -e "\nUpdating configuration file..."
  cat <<EOL > /etc/default/noip-duc
NOIP_USERNAME=$ddns_username
NOIP_PASSWORD=$ddns_password
NOIP_HOSTNAMES=all.ddnskey.com
EOL

  echo "Configuration complete. The credentials have been saved to /etc/default/noip-duc."

  # Restart the service after updating credentials
  systemctl restart noip-duc.service

  # Check status after restarting the service
  check_update_status
done

# Check if the service is running
if systemctl is-active --quiet noip-duc.service; then
  echo -e "The noip-duc service started successfully.\n"

  # Ask the user if they want to enable the service to run at startup
  read -p "Do you want to enable the noip-duc service to run automatically at startup? (y/n): " enable_response
  if [[ "$enable_response" == "y" || "$enable_response" == "Y" ]]; then
    systemctl enable noip-duc.service
    echo -e "\nThe noip-duc service is now enabled to start at boot."
  else
    read -p $'\nAre you sure you want to keep it deactivated? Without it, your hostname will NOT be automatically updated with your IP address after the next boot. (y/n): ' confirm_response
    if [[ "$confirm_response" == "n" || "$confirm_response" == "N" ]]; then
      systemctl enable noip-duc.service
      echo -e "\nThe noip-duc service is now enabled to start at startup."
    else
      systemctl disable noip-duc.service
      echo -e "\nThe noip-duc service is now disabled and will NOT run at startup."
    fi
  fi
else
  echo -e "\nThe noip-duc service failed to start. Please check the logs with 'journalctl -u noip-duc.service' for more information."
fi

# Completion message
echo -e "\nInstallation and configuration are complete. Use 'noip-duc --help' for additional options."
echo -e "For further assistance please visit https://www.noip.com/support/.\n\nThank you for choosing noip.com.\n"
exit 0
