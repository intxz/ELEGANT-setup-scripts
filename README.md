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

`wget -qO- https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/master/setup_docker.sh | bash`

**Option 2: Download, review, and then run (recommended)**

```bash
wget https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/master/setup_docker.sh
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
wget -qO- https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/master/setup_nvidia.sh | bash
```

**Option 2: Download, review, and then run (recommended)**

```bash
wget https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/master/setup_nvidia.sh
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
