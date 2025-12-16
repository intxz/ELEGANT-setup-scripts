# 🌐 ELEGANT Setup 📡

A collection of scripts to quickly and cleanly configure an Ubuntu server.  
Each step corresponds to the installation of an essential component, with automated scripts that follow the official documentation but include practical improvements.

---

## Prerequisite: install `wget`

Before downloading and running the scripts from GitHub, make sure `wget` is installed:

```bash
sudo apt-get update -y
sudo apt-get install -y wget
```

## 1. How Install Docker

This script installs Docker Engine on Ubuntu following the [official Docker documentation](https://docs.docker.com/engine/install/ubuntu/)

### What does this script do?

- Configures the official Docker repositories on your system.
- Imports Docker’s GPG key using **gnupg**  
  _(this ensures the packages are authentic and prevents security warnings)_.
- Installs:
  - Docker Engine (`docker-ce`)
  - Docker CLI
  - Containerd
  - Official extensions (`buildx` and `compose`)
- Runs the `hello-world` container to verify the installation.
- Adds your user to the `docker` group so you don’t need to use `sudo` with every command.

### How to run the script

**Option 1: Run directly from GitHub**

`wget -qO- https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/main/setup_docker.sh | bash`

**Option 2: Download, review, and then run (recommended)**

```bash
wget https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/main/setup_docker.sh
chmod +x setup_docker.sh
./setup_docker.sh
```

## 2. How to Install NVIDIA Drivers + CUDA

This script installs the **NVIDIA proprietary drivers** and the **CUDA toolkit** on Ubuntu, following the [official NVIDIA installation guide](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/).

### What does this script do?

- Checks if an NVIDIA GPU is detected in your system (`lspci`).
- Updates and upgrades the system packages.
- Installs prerequisites (`build-essential`, `dkms`, `gnupg`, etc.).
- Adds the official NVIDIA CUDA repository.
- Installs both:
  - NVIDIA drivers
  - CUDA toolkit (latest version available for your Ubuntu release)
- Prompts for reboot after installation so the drivers can be loaded.
- After reboot, you can run `nvidia-smi` to confirm that the GPU is working.

### How to run the script

**Option 1: Run directly from GitHub**

```bash
wget -qO- https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/main/setup_nvidia.sh | bash
```

**Option 2: Download, review, and then run (recommended)**

```bash
wget https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/main/setup_nvidia.sh
chmod +x setup_nvidia.sh
./setup_nvidia.sh
```

### Post-installation

- Reebot the machine:

`sudo reboot`

- Verify that the GPU is detectd and drivers are working

`nvidia-smi`

- You should see something like this:

```bash
+-----------------------------------------------------------------------------+
| NVIDIA-SMI XXX.XX.XX    Driver Version: XXX.XX.XX    CUDA Version: XX.X     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  NVIDIA GPU      On       | 00000000:00:00.0 Off |                  0   |
|  0%   00C    P8     XXW / XXXW|     0MiB /  XXXXMiB  |     0%      Default  |
+-------------------------------+----------------------+----------------------+

+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

## How to Install OWAMP (perfSONAR)

This script installs the One-Way Active Measurement Protocol (OWAMP) tools on Ubuntu. Unlike standard tools like Ping or iperf (which measure Round-Trip Time), OWAMP measures precise One-Way Delay, making it essential for detecting network asymmetry and routing issues. It uses the official [perfSONAR repositories](https://docs.perfsonar.net/).

### What does this script do?

- Installs curl (required for fetching keys).

- Adds the official perfSONAR repository list to your system (since these packages are not in the default Ubuntu repos).

- Securely imports the perfSONAR GPG signing key.

- Updates package lists and installs:

  - owamp-server (The daemon that listens for tests)

  - owamp-client (The owping command-line tool)

- Verifies that the owamp-server service is active and running.

### How to run the script 

**Option 1: Run directly from GitHub**

```bash
wget -qO- https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/main/setup_owamp.sh | bash
```

**Option 2: Download, review, and then run (recommended)**

```bash
wget https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/main/setup_owamp.sh
chmod +x setup_owamp.sh
./setup_owamp.sh
```
### Pos-Instalation (Important)

By default, the OWAMP server denies all connections for security. To allow testing, you must configure the Access Control Lists (ACLs).

1. Edit the limits file:

```bash
sudo nano /etc/owamp-server/owamp-server.limits
```

2. Add the following configuration to allow "Open Mode" testing (allows anyone to test against your server):

```bash
limit root with
  allow_open_mode on
  bandwidth 0
  disk 0
  delete_on_fetch on

assign default root
```

3. Restart the service to apply changes:

```bash
sudo systemctl restart owamp-server
```

4. Verify the installation by running a test against yourself (loopback):
```bash
owping 127.0.0.1
```

### How to run

1. **On the Server (Receiver)** The server runs as a background daemon. You don't need to run a command for every test, just ensure the service is active and ports are open (TCP 861 and UDP range 8760-9960).

```bash
sudo systemctl status owamp-server
```

2. **On the Client (Sender)** Use owping to send packets. Example: Send 100 packets (`-c 100`) with a 0.1s interval (`-i 0.1`) to the server IP.

```bash
owping -c 100 -i 0.1 <SERVER_IP_ADDRESS>
```

3. **Expected Output** You should see statistics separated for the Sender (Client -> Server) and Receiver (Server -> Client). This allows you to detect if one direction is slower than the other.

```bash
--- owping statistics ---
Sid:    c0a8016f4d5e12345678901234567890
Server: [192.168.1.50]:861
Client: [192.168.1.14]:44832
--
One-way delay stats (Sender): #UPlink
  Pkts: 100  Lost: 0 (0.00%)
  Min/Median/Max: 0.143 / 0.150 / 0.210 ms
  Error Estimate: 0.025 ms

One-way delay stats (Receiver): #DOWNlink
  Pkts: 100  Lost: 0 (0.00%)
  Min/Median/Max: 0.138 / 0.142 / 0.198 ms
  Error Estimate: 0.030 ms
```