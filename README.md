
# RouterOS Installation Script

This project provides a streamlined solution for installing RouterOS CHR (Cloud Hosted Router) using a simple DD method. It automates the setup process, ensuring a smooth and efficient installation experience on Linux systems.

## Features

- **Automated Installation**: Simplifies the deployment of RouterOS CHR using a single command.
- **Compatibility**: Designed to work seamlessly with most Linux distributions.
- **Efficient Setup**: Includes optimizations to reduce setup time and minimize manual configuration.

## Prerequisites

- A Linux environment with root privileges.
- Ensure `wget` and `chmod` are installed on the system.

## How to Use

1. Download the installation script:
   ```sh
   wget -qO ddros-pub.sh --no-check-certificate https://github.com/xmanlucian/DD_RouterOS/blob/main/ddros-pub.sh
   ```

2. Make the script executable:
   ```sh
   chmod +x ddros-pub.sh
   ```

3. Run the script to start the installation:
   ```sh
   ./ddros-pub.sh
   ```

## What the Script Does

- Downloads the latest RouterOS CHR image.
- Configures the system for RouterOS installation.
- Writes the RouterOS image to the appropriate disk using DD.
- Automates basic setup tasks to get your RouterOS instance running quickly.

## Why Use This Script?

- **Time-Saving**: Reduces the manual steps required for installation.
- **Reliable**: Designed to handle common installation challenges.
- **Easy to Use**: No advanced knowledge required—just follow the steps.

## Contribution

Contributions are welcome! Feel free to fork the repository and submit pull requests. Suggestions for improvements or new features are highly appreciated.

## License

This project is open-source and distributed under the [MIT License](https://opensource.org/licenses/MIT). See the LICENSE file for more information.

---

Simplify your RouterOS CHR installation with this quick and reliable script. Get started now and enjoy the power of automated deployment!
"""
