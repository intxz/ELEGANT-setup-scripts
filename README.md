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

```bash 
wget -qO- https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/master/setup_docker.sh | bash
```

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
wget -qO- https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/master/setup_owampd.sh | bash
```

**Option 2: Download, review, and then run (recommended)**

```bash
wget https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/master/setup_owampd.sh
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
limit root with allow_open_mode on bandwidth 0 disk 0 delete_on_fetch on
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
---

## 4. LiteLLM Gateway (Ollama API Proxy)

Este script configura un **API Gateway** usando LiteLLM para exponer tu modelo Ollama (Qwen) como una API compatible con OpenAI, multi-usuario con prioridad.

### Sistema de prioridades

| Usuario | Prioridad | Descripción |
|---------|-----------|-------------|
| **premium** | 1 (más alta) | Tú - acceso inmediato cuando lo necesites |
| **trial** | 3 (baja) | Otros - acceso cuando premium no usa |

**Sin límites de tokens** - todos pueden usar los que necesiten. La prioridad solo afecta cuando hay congestión: tus requests van primero.

### Casos de uso

- Exponer Ollama local (Qwen) como API OpenAI-compatible
- Multi-usuario con diferenciación por prioridad
- Dashboard web para gestión y monitoreo
- Conectar AI coding agents: **OpenCode**, **OpenClaw**, **Claude Code**, **Continue.dev**, etc.

### Requisitos

- Docker y Docker Compose instalados
- Ollama corriendo con al menos un modelo Qwen
- Acceso a la VM vía VPN (puerto 4000)

### Modelo disponible

| Modelo | Descripción |
|--------|-------------|
| `qwen-35b` | Qwen 3.6 35B - accesible por todos los usuarios |

### Cómo ejecutar el script

**Opción 1: Ejecutar directamente desde GitHub**

```bash
wget -qO- https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/master/setup_litellm.sh | bash
```

**Opción 2: Descargar, revisar, y luego ejecutar (recomendado)**

```bash
wget https://raw.githubusercontent.com/intxz/ELEGANT-setup-scripts/master/setup_litellm.sh
chmod +x setup_litellm.sh
./setup_litellm.sh
```

### Qué hace el script

1. **Verifica** Docker y Ollama
2. **Crea** el directorio `~/litellm-gateway` con:
   - `docker-compose.yml` (LiteLLM + PostgreSQL)
   - `config.yaml` (modelo único, sin límites de tokens)
3. **Genera** master key para administración
4. **Inicia** los servicios en Docker
5. **Crea** usuarios con niveles de prioridad:
   - **premium** (prioridad 1): Tú
   - **trial** (prioridad 3): Otros
6. **Genera** API keys para cada usuario
7. **Muestra** resumen con todas las claves

### Después de ejecutar

El script mostrará las API keys. **Guarda estos archivos**:

```
~/litellm-gateway/.master_key    # Clave maestra admin
~/litellm-gateway/.api_keys      # API keys de usuarios
```

### Endpoints disponibles

| Endpoint | Descripción |
|----------|-------------|
| `http://TU_VM:4000/v1/chat/completions` | API OpenAI-compatible |
| `http://TU_VM:4000/ui` | Dashboard web |
| `http://TU_VM:4000/docs` | Swagger API docs |

### Cómo usar las API keys

**OpenCode** (config en `~/.config/opencode/opencode.json`):

```json
{
  "provider": {
    "ollama-gateway": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Qwen via LiteLLM",
      "options": {
        "baseURL": "http://172.16.67.208:4000/v1"
      },
      "models": {
        "qwen-35b": {
          "name": "Qwen 3.6 35B"
        }
      }
    }
  }
}
```

**OpenAI SDK (cualquier cliente)**:

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-xxxx-your-premium-key-xxxx",
    base_url="http://172.16.67.208:4000/v1"
)

response = client.chat.completions.create(
    model="qwen-35b",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

### Ver estado de los servicios

```bash
cd ~/litellm-gateway
docker compose ps
docker compose logs -f
```

### Comandos útiles de administración

```bash
# Obtener master key
source ~/litellm-gateway/.master_key

# Ver usuarios
curl http://localhost:4000/user/info?user_id=premium \
  -H "Authorization: Bearer $MASTER_KEY"

# Ver API keys
curl http://localhost:4000/key/info?key=$API_KEY \
  -H "Authorization: Bearer $MASTER_KEY"

# Crear nuevo usuario con prioridad
curl -X POST http://localhost:4000/user/new \
  -H "Authorization: Bearer $MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"user_id": "nombre", "max_budget": 999999, "metadata": {"priority": 2}}'

# Generar API key para nuevo usuario
curl -X POST http://localhost:4000/key/generate \
  -H "Authorization: Bearer $MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"user_id": "nombre", "models": ["qwen-35b"]}'
```

### Niveles de prioridad

| Valor | Nivel |
|-------|-------|
| 1 | Más alto - premium |
| 2 | Medio |
| 3 | Bajo - trial |
