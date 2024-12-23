
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

## Future Plans

We aim to enhance this script and related features to offer a more robust and versatile tool for deploying and managing RouterOS CHR. Here’s what we plan to add in the future:
	###1.	Pre-configuration Enhancements:
	-	Automate the initial setup of RouterOS CHR, including network interface settings, DNS configurations, and firewall rules.
	-	Simplify license registration and ensure the system is ready for use immediately post-deployment.
	###2.	Failover and High Availability:
	-	Integrate Virtual Router Redundancy Protocol (VRRP) for dual-machine hot standby, ensuring high availability.
	-	Develop tools for automated failover testing to verify system reliability during failures.
	###3.	Containerized Deployment:
	-	Enable the use of containers to deploy network monitoring tools and security applications directly on RouterOS.
	-	Introduce a management system for container lifecycle operations, such as updates and monitoring.
	###4.	Python Integration for Advanced Features:
	-	Implement automated backup and recovery scripts to protect system configurations.
	-	Develop real-time monitoring tools for resource usage and performance metrics, with alerts for threshold breaches.
	-	Introduce advanced network optimization tools for bandwidth management and latency analysis.
	-	Integrate external APIs for threat intelligence and configuration synchronization.

## License

This project is open-source and distributed under the [MIT License](https://opensource.org/licenses/MIT). See the LICENSE file for more information.

---

Simplify your RouterOS CHR installation with this quick and reliable script. Get started now and enjoy the power of automated deployment!
"""
