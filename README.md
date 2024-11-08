# No-IP DUC Installation & Configuration Automation Script

## Overview

This script automates the installation, configuration, and management of the No-IP Dynamic Update Client (DUC). It simplifies the installation process, ensures compatibility with various system architectures, and makes it easy for users to manage and update their DDNS credentials. This script is particularly useful for users with limited Linux experience or those who prefer a hassle-free installation and configuration process.

## Features

- **Root Privilege Verification**: Ensures the script runs with appropriate permissions.
- **Automatic Package Detection**: Detects the system architecture (x86_64, arm64, armv7l).
- **Installation of No-IP DUC**: Automatically installs the appropriate .deb package for the user's system.
- **Credential Management**: Prompts the user for DDNS credentials and securely writes them to `/etc/default/noip-duc`.
- **Service Management**: Ensures the No-IP DUC service is running and configured correctly. Monitors its status and allows for automatic reconfiguration if there are issues with the service.
- **Startup Enablement**: Prompts the user to enable the service to start on boot and provides confirmation to prevent accidental deactivation.
- **Seamless Credential Updates**: Re-running the script will allow users to easily update their DDNS credentials without manual editing of configuration files.

## Installation

### Requirements:
- A Linux-based operating system (Debian-based distributions such as Ubuntu are recommended).
- Root privileges.

### Automated install:
   ```bash
   sudo curl -L https://github.com/AchrosEsson/noip-duc-install/raw/main/duc-install.sh -o duc-install.sh && sudo chmod +x duc-install.sh && sudo ./duc-install.sh
   ```
### Steps to Install manually:
1. **Download the script**:
   ```bash
   wget ttps://github.com/AchrosEsson/noip-duc-install/raw/main/duc-install.sh
   ```
2. **Make the script executable**:
   ```bash
   chmod +x install.sh

3. **Run the script**:
   ```bash
   ./install.sh
   
4. **Follow the prompts in the script to:**
   - Enter your DDNS username and password.
   - Choose whether to enable the No-IP DUC service to start on boot.

5. **Updating Credentials**:
   - To update your DDNS credentials, simply re-run the script. It will prompt you for your new credentials and automatically update the configuration file.
<br>

# License

This script is provided free of charge under the MIT License.

### Feedback & Contributions

If you have any feedback, encounter issues, or would like to contribute to the project, feel free to open an issue or submit a pull request on the GitHub repository.

Thank you for using the No-IP DUC installation script! I hope this helps streamline the setup and management of the No-IP Dynamic DNS service.



