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
