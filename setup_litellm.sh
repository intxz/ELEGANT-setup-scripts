#!/bin/bash
set -e

###############################################
# LiteLLM Gateway Setup for Ollama Qwen
# Premium Priority + Trial (No token limits)
###############################################

set -e

echo "=============================================="
echo " LiteLLM Gateway Setup - ELEGANT Framework"
echo " Premium Priority Mode (No Token Limits)"
echo "=============================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
WORKDIR="$HOME/litellm-gateway"
DB_PASSWORD="litellm_password_2024"

# Functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found. Installing..."
        sudo apt update && sudo apt install -y docker.io docker-compose
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        log_warn "Docker installed. You may need to logout/login."
    fi
    docker --version
}

check_ollama() {
    log_info "Checking Ollama..."
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        MODELS=$(curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
        log_info "Ollama running. Models: $MODELS"
    else
        log_error "Ollama not running. Please start: ollama serve"
        exit 1
    fi
}

generate_master_key() {
    log_info "Generating master key..."
    MASTER_KEY=$(openssl rand -hex 16)
    echo "export LITELLM_MASTER_KEY=$MASTER_KEY" > "$WORKDIR/.master_key"
    chmod 600 "$WORKDIR/.master_key"
    echo "Master Key saved to: $WORKDIR/.master_key"
}

create_docker_compose() {
    log_info "Creating docker-compose.yml..."

    cat > "$WORKDIR/docker-compose.yml" << 'EOF'
services:
  litellm:
    image: ghcr.io/berriai/litellm:main
    container_name: litellm
    ports:
      - "4000:4000"
    environment:
      - DATABASE_URL=postgresql://litellm:litellm_password_2024@postgres:5432/litellm
      - LITELLM_MASTER_KEY=${LITELLM_MASTER_KEY}
      - LITELLM_MIGRATION_VERSION=3
      - UI_USERNAME=admin
      - UI_PASSWORD=admin_litellm_2024
    volumes:
      - ./config.yaml:/app/config.yaml
    depends_on:
      - postgres
    restart: unless-stopped
    extra_hosts:
      - "host.docker.internal:host-gateway"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:16-alpine
    container_name: litellm-postgres
    environment:
      - POSTGRES_USER=litellm
      - POSTGRES_PASSWORD=litellm_password_2024
      - POSTGRES_DB=litellm
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U litellm -d litellm"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
EOF
}

create_config() {
    log_info "Creating config.yaml..."

    # Load master key
    source "$WORKDIR/.master_key"

    cat > "$WORKDIR/config.yaml" << 'EOF'
model_list:
  # Single model with priority routing
  - model_name: qwen-35b
    litellm_params:
      model: openai/qwen3.6:35b
      api_base: http://host.docker.internal:11434/v1
      api_key: dummy
      timeout: 600
      stream_timeout: 600

general_settings:
  master_key: ${LITELLM_MASTER_KEY}
  database_url: postgresql://litellm:litellm_password_2024@postgres:5432/litellm
  stream_timeout: 600
  proxy_batch_write_at: 10
  queue_settings:
    no_rate_limit: true  # NO token limits

litellm_settings:
  drop_params: true
  set_verbose: false
  json_logs: false

environment_variables:
  DATABASE_URL: "postgresql://litellm:litellm_password_2024@postgres:5432/litellm"
EOF
}

start_services() {
    log_info "Starting Docker services..."

    cd "$WORKDIR"
    source "$WORKDIR/.master_key"

    docker compose up -d

    log_info "Waiting for services..."
    sleep 15

    docker compose ps
}

create_users_with_priority() {
    log_info "Creating users with priority levels..."

    source "$WORKDIR/.master_key"
    MASTER_KEY="${LITELLM_MASTER_KEY}"

    # Wait for LiteLLM to be ready
    until curl -s http://localhost:4000/health > /dev/null 2>&1; do
        echo "Waiting for LiteLLM..."
        sleep 5
    done

    # Create Premium user (priority=1 = highest)
    log_info "Creating Premium user..."
    curl -s -X POST http://localhost:4000/user/new \
      -H "Authorization: Bearer $MASTER_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "user_id": "premium",
        "max_budget": 999999,
        "metadata": {
          "tier": "premium",
          "priority": 1,
          "description": "Premium user - highest priority"
        }
      }' | tee -a "$WORKDIR/.api_keys"

    # Create Trial user (priority=3 = lowest)
    log_info "Creating Trial user..."
    curl -s -X POST http://localhost:4000/user/new \
      -H "Authorization: Bearer $MASTER_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "user_id": "trial",
        "max_budget": 999999,
        "metadata": {
          "tier": "trial",
          "priority": 3,
          "description": "Trial user - standard priority"
        }
      }' | tee -a "$WORKDIR/.api_keys"

    # Generate API keys
    log_info "Generating API keys..."

    echo "" >> "$WORKDIR/.api_keys"
    echo "=== API KEYS ===" >> "$WORKDIR/.api_keys"

    PREMIUM_KEY=$(curl -s -X POST http://localhost:4000/key/generate \
      -H "Authorization: Bearer $MASTER_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "user_id": "premium",
        "models": ["qwen-35b"],
        "metadata": {"tier": "premium", "priority": 1}
      }' | grep -o '"key":"[^"]*"' | cut -d'"' -f4)

    echo "PREMIUM_KEY: $PREMIUM_KEY" >> "$WORKDIR/.api_keys"

    TRIAL_KEY=$(curl -s -X POST http://localhost:4000/key/generate \
      -H "Authorization: Bearer $MASTER_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "user_id": "trial",
        "models": ["qwen-35b"],
        "metadata": {"tier": "trial", "priority": 3}
      }' | grep -o '"key":"[^"]*"' | cut -d'"' -f4)

    echo "TRIAL_KEY: $TRIAL_KEY" >> "$WORKDIR/.api_keys"
}

show_summary() {
    echo ""
    echo "=============================================="
    echo " Setup Complete!"
    echo "=============================================="
    echo ""
    echo "Services:"
    echo "  - LiteLLM Proxy: http://localhost:4000"
    echo "  - LiteLLM UI:    http://localhost:4000/ui"
    echo ""
    echo "Files:"
    echo "  - Master Key: $WORKDIR/.master_key"
    echo "  - API Keys:   $WORKDIR/.api_keys"
    echo ""

    if [ -f "$WORKDIR/.api_keys" ]; then
        cat "$WORKDIR/.api_keys"
    fi
}

main() {
    log_info "Starting LiteLLM Gateway Setup..."

    check_docker
    check_ollama

    mkdir -p "$WORKDIR"
    cd "$WORKDIR"

    generate_master_key
    create_docker_compose
    create_config
    start_services
    create_users_with_priority
    show_summary

    log_info "Done!"
}

main "$@"