#!/bin/bash
set -e

###############################################
# LiteLLM Gateway Setup for Ollama Qwen
# Premium + Trial Multi-User API Gateway
###############################################

set -e

echo "=============================================="
echo " LiteLLM Gateway Setup - ELEGANT Framework"
echo "=============================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
WORKDIR="$HOME/litellm-gateway"
OLLAMA_MODEL="qwen3.6:35b"
DB_PASSWORD="litellm_password_2024"
POSTGRES_USER="litellm"
POSTGRES_DB="litellm"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found. Installing..."
        sudo apt update && sudo apt install -y docker.io docker-compose
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        log_warn "Docker installed. You may need to logout/login for group changes."
    fi
    docker --version
}

check_ollama() {
    log_info "Checking Ollama..."
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        MODELS=$(curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
        log_info "Ollama is running. Models: $MODELS"
        
        # Check if qwen model exists
        if echo "$MODELS" | grep -qi "qwen"; then
            log_info "Qwen model found!"
        else
            log_warn "No Qwen model found. You may need to run: ollama pull $OLLAMA_MODEL"
        fi
    else
        log_error "Ollama not running. Please start it with: ollama serve"
        exit 1
    fi
}

create_directory() {
    log_info "Creating working directory..."
    mkdir -p "$WORKDIR"
    cd "$WORKDIR"
    pwd
}

create_docker_compose() {
    log_info "Creating docker-compose.yml..."
    
    # Generate master key
    MASTER_KEY=$(openssl rand -hex 16)
    echo "export LITELLM_MASTER_KEY=$MASTER_KEY" > "$WORKDIR/.master_key"
    
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

networks:
  default:
    name: litellm-network
EOF
    echo "Master Key saved to: $WORKDIR/.master_key"
}

create_config() {
    log_info "Creating config.yaml..."
    
    cat > "$WORKDIR/config.yaml" << 'EOF'
model_list:
  # Premium Tier - High resources, priority access
  - model_name: qwen-premium
    litellm_params:
      model: openai/qwen3.6:35b
      api_base: http://host.docker.internal:11434/v1
      api_key: dummy
      rpm_limit: 500
      tpm_limit: 10000
      timeout: 600
      stream_timeout: 600

  # Trial Tier - Limited resources
  - model_name: qwen-trial
    litellm_params:
      model: openai/qwen3.6:35b
      api_base: http://host.docker.internal:11434/v1
      api_key: dummy
      rpm_limit: 50
      tpm_limit: 1000
      timeout: 600
      stream_timeout: 600

  # Default access model
  - model_name: qwen3.6:35b
    litellm_params:
      model: openai/qwen3.6:35b
      api_base: http://host.docker.internal:11434/v1
      api_key: dummy
      rpm_limit: 200
      tpm_limit: 5000
      timeout: 600
      stream_timeout: 600

general_settings:
  master_key: ${LITELLM_MASTER_KEY}
  database_url: postgresql://litellm:litellm_password_2024@postgres:5432/litellm
  stream_timeout: 600
  proxy_batch_write_at: 10

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
    
    log_info "Waiting for services to be ready..."
    sleep 15
    
    # Check containers
    docker compose ps
}

create_users() {
    log_info "Creating users and API keys..."
    
    cd "$WORKDIR"
    source "$WORKDIR/.master_key"
    MASTER_KEY="${LITELLM_MASTER_KEY}"
    
    # Check if LiteLLM is ready
    until curl -s http://localhost:4000/health > /dev/null 2>&1; do
        echo "Waiting for LiteLLM to be ready..."
        sleep 5
    done
    
    # Create Premium User
    log_info "Creating Premium user..."
    PREMIUM_RESPONSE=$(curl -s -X POST http://localhost:4000/user/new \
      -H "Authorization: Bearer $MASTER_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "user_id": "premium",
        "max_budget": 999999,
        "tpm_limit": 10000,
        "rpm_limit": 500,
        "metadata": {"tier": "premium", "description": "Premium user - unlimited budget"}
      }')
    
    echo "Premium user response: $PREMIUM_RESPONSE"
    
    # Create Trial User
    log_info "Creating Trial user..."
    TRIAL_RESPONSE=$(curl -s -X POST http://localhost:4000/user/new \
      -H "Authorization: Bearer $MASTER_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "user_id": "trial",
        "max_budget": 10,
        "budget_duration": "30d",
        "tpm_limit": 1000,
        "rpm_limit": 50,
        "metadata": {"tier": "trial", "description": "Trial user - limited budget"}
      }')
    
    echo "Trial user response: $TRIAL_RESPONSE"
    
    # Generate Premium API Key
    log_info "Generating Premium API key..."
    PREMIUM_KEY=$(curl -s -X POST http://localhost:4000/key/generate \
      -H "Authorization: Bearer $MASTER_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "user_id": "premium",
        "models": ["qwen-premium"],
        "metadata": {"tier": "premium"}
      }' | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    
    # Generate Trial API Key
    log_info "Generating Trial API key..."
    TRIAL_KEY=$(curl -s -X POST http://localhost:4000/key/generate \
      -H "Authorization: Bearer $MASTER_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "user_id": "trial",
        "models": ["qwen-trial"],
        "metadata": {"tier": "trial"}
      }' | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    
    # Save API keys
    cat > "$WORKDIR/.api_keys" << EOF
==============================================
 LiteLLM API Keys - SAVE THESE!
==============================================

MASTER_KEY: $MASTER_KEY

PREMIUM_USER_API_KEY: $PREMIUM_KEY
  - Models: qwen-premium
  - TPM: 10000, RPM: 500
  - Budget: Unlimited

TRIAL_USER_API_KEY: $TRIAL_KEY
  - Models: qwen-trial
  - TPM: 1000, RPM: 50
  - Budget: \$10/month

==============================================
EOF
    
    echo ""
    log_info "API keys saved to: $WORKDIR/.api_keys"
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
    echo "IMPORTANT FILES:"
    echo "  - Master Key: $WORKDIR/.master_key"
    echo "  - API Keys:   $WORKDIR/.api_keys"
    echo ""
    echo "To view logs:"
    echo "  cd $WORKDIR && docker compose logs -f"
    echo ""
    echo "To check status:"
    echo "  cd $WORKDIR && docker compose ps"
    echo ""
    
    if [ -f "$WORKDIR/.api_keys" ]; then
        cat "$WORKDIR/.api_keys"
    fi
}

# Main execution
main() {
    log_info "Starting LiteLLM Gateway Setup..."
    echo ""
    
    check_docker
    check_ollama
    create_directory
    create_docker_compose
    create_config
    start_services
    create_users
    show_summary
    
    log_info "Done!"
}

main "$@"