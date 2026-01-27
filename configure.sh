#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# ASCII art banner
echo -e "${BLUE}  ____              _        _      "
echo " / ___|_      _____| |_ _ __(_)_  __"
echo " \___ \ \ /\ / / _ \ __| '__| \ \/ /"
echo "  ___) \ V  V /  __/ |_| |  | |>  < "
echo " |____/ \_/\_/ \___|\__|_|  |_/_/\_\\"
echo
echo -e "${NC}"

# Tool description
echo -e "Welcome to the Swetrix CE configuration tool!"
echo -e "This utility helps you set up your Swetrix CE environment by configuring essential parameters"
echo -e "and generating secure credentials for your installation to get you started as quickly as possible.\n"

# Function to generate a random string
generate_random_string() {
  openssl rand -base64 48
}

# Helper: check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Helper: OS detection
is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

is_debian_like() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    if echo "$ID" | grep -qiE 'debian|ubuntu'; then
      return 0
    fi
    if echo "$ID_LIKE" | grep -qi 'debian'; then
      return 0
    fi
  fi
  return 1
}

# Configure Docker's official APT repository (Ubuntu/Debian)
configure_docker_apt_repository() {
  if ! is_debian_like; then
    return 1
  fi

  echo -e "${BLUE}Configuring Docker APT repository...${NC}"

  # Identify distro path and codename for the repo
  . /etc/os-release
  distro_path="ubuntu"
  codename="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
  if echo "$ID" | grep -qi 'debian'; then
    distro_path="debian"
    codename="$VERSION_CODENAME"
  fi

  # Ensure prerequisites
  sudo apt-get update -y >/dev/null 2>&1 || true
  sudo apt-get install -y ca-certificates curl gnupg >/dev/null 2>&1 || true

  # Setup keyring
  sudo install -m 0755 -d /etc/apt/keyrings 2>/dev/null || true
  if ! sudo curl -fsSL "https://download.docker.com/linux/${distro_path}/gpg" -o /etc/apt/keyrings/docker.asc; then
    echo -e "${YELLOW}Warning:${NC} Failed to download Docker GPG key. Continuing without repo configuration."
    return 1
  fi
  sudo chmod a+r /etc/apt/keyrings/docker.asc 2>/dev/null || true

  # Write sources list
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${distro_path} ${codename} stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  # Update package lists
  if ! sudo apt-get update; then
    echo -e "${YELLOW}Warning:${NC} apt-get update failed after adding Docker repo."
    return 1
  fi

  echo -e "${GREEN}Docker APT repository configured (${distro_path} ${codename}).${NC}"
  return 0
}

# Installer: Debian/Ubuntu via apt
install_docker_apt() {
  echo
  read -p "Docker is not installed. Install Docker Engine via apt now? (Y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    return 1
  fi

  echo -e "${GREEN}Installing Docker (requires sudo)...${NC}"
  if ! sudo apt-get update; then
    echo -e "${RED}apt-get update failed. Please install Docker manually.${NC}"
    return 1
  fi

  # Prefer distro packages for simplicity and reliability
  if ! sudo apt-get install -y docker.io; then
    echo -e "${RED}Failed to install docker.io via apt. Please install Docker manually.${NC}"
    return 1
  fi

  # Start and enable Docker if systemd is available
  if command_exists systemctl; then
    sudo systemctl enable --now docker 2>/dev/null || true
  fi

  # Allow current user to use docker without sudo (user must re-login)
  if command_exists usermod; then
    sudo usermod -aG docker "$USER" 2>/dev/null || true
  fi

  return 0
}

install_compose_apt() {
  echo
  read -p "Docker Compose is not installed. Install Compose plugin via apt now? (Y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    return 1
  fi

  echo -e "${GREEN}Installing Docker Compose (requires sudo)...${NC}"

  # Try the modern plugin first from current repos
  if sudo apt-get update && sudo apt-get install -y docker-compose-plugin; then
    if docker compose version >/dev/null 2>&1; then
      return 0
    fi
  fi

  # Configure Docker's official repo and retry (per docs)
  if configure_docker_apt_repository; then
    if sudo apt-get install -y docker-compose-plugin; then
      if docker compose version >/dev/null 2>&1; then
        return 0
      fi
    fi
  fi

  # Fallback to legacy docker-compose package if plugin not available
  if sudo apt-get install -y docker-compose; then
    if command_exists docker-compose; then
      return 0
    fi
  fi

  echo -e "${RED}Failed to install Docker Compose via apt. Please install it manually.${NC}"
  return 1
}

print_manual_docker_instructions() {
  echo -e "${YELLOW}Docker is required to run Swetrix via Docker Compose.${NC}"
  if is_macos; then
    echo "On macOS, install Docker Desktop:"
    echo "  - Using Homebrew: brew install --cask docker"
    echo "  - Or download: https://www.docker.com/products/docker-desktop/"
    echo "After installation, start Docker Desktop."
  else
    echo "Please install Docker for your OS: https://docs.docker.com/engine/install/"
  fi
}

print_manual_compose_instructions() {
  echo -e "${YELLOW}Docker Compose is required. Install one of the following:${NC}"
  if is_macos; then
    echo "On macOS with Docker Desktop, 'docker compose' is included."
    echo "Alternatively: brew install docker-compose"
  else
    echo "For Linux, prefer the Compose plugin (docker compose)."
    echo "Docs: https://docs.docker.com/compose/install/"
  fi
}

preflight_check() {
  echo -e "${BLUE}Running preflight checks...${NC}"

  # Docker check
  if command_exists docker; then
    echo -e "${GREEN}Docker found:$(docker --version 2>/dev/null | sed 's/^/ /')${NC}"
  else
    if is_debian_like; then
      install_docker_apt || print_manual_docker_instructions
    else
      print_manual_docker_instructions
    fi
  fi

  # Compose check (either 'docker compose' or 'docker-compose')
  if docker compose version >/dev/null 2>&1; then
    echo -e "${GREEN}Docker Compose (plugin) found: $(docker compose version 2>/dev/null | head -n1)${NC}"
  elif command_exists docker-compose; then
    echo -e "${GREEN}Docker Compose found: $(docker-compose --version 2>/dev/null)${NC}"
  else
    if is_debian_like; then
      install_compose_apt || print_manual_compose_instructions
    else
      print_manual_compose_instructions
    fi
  fi

  # Re-check and warn if still missing
  missing=""
  if ! command_exists docker; then
    missing="docker"
  fi
  if ! docker compose version >/dev/null 2>&1 && ! command_exists docker-compose; then
    if [ -n "$missing" ]; then
      missing=", $missing compose"
    else
      missing="docker compose"
    fi
  fi
  if [ -n "$missing" ]; then
    echo -e "${YELLOW}Warning:${NC} Missing $missing. You can continue generating the .env, but you'll need to install these before running Swetrix."
  fi
}

# Run preflight checks before configuration prompts
preflight_check

# Check if .env exists
if [ -f .env ]; then
  echo
  echo -e "${YELLOW}Warning: .env file already exists!${NC}"
  read -p "Do you want to continue and overwrite it? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
  fi
fi

# Create/overwrite .env file
echo
echo -e "${GREEN}Creating new .env file...${NC}"

echo -e "# Swetrix Frontend configuration" > .env

# BASE_URL
while true; do
  echo
  read -e -p "Enter public URL of your Swetrix instance (required, e.g., https://swetrix.example.com): " base_url
  if [ -n "$base_url" ]; then
    base_url="$(echo "$base_url" | sed 's:/*$::')"
    echo "BASE_URL=$base_url" >> .env
    break
  else
    echo -e "${RED}BASE_URL is required. Please enter a value.${NC}"
  fi
done

echo -e "\n# Swetrix API configuration" >> .env

# Secret key base
echo
read -e -p "Enter SECRET_KEY_BASE (press Enter to auto-generate): " secret_key_base
if [ -z "$secret_key_base" ]; then
  secret_key_base=$(generate_random_string)
  echo -e "${GREEN}Generated SECRET_KEY_BASE${NC}"
fi
echo "SECRET_KEY_BASE=$secret_key_base" >> .env

# Debug mode (always false)
echo "DEBUG_MODE=false" >> .env
echo "IP_GEOLOCATION_DB_PATH=" >> .env
echo "DISABLE_REGISTRATION=true" >> .env

echo -e "\n\n# Keep these empty unless you manually set passwords for your databases" >> .env
echo "REDIS_PASSWORD=" >> .env
echo "CLICKHOUSE_PASSWORD=" >> .env

echo -e "\n${GREEN}Configuration complete! .env file has been created.${NC}"
echo -e "${YELLOW}Note: Make sure to review the .env file before starting the application.${NC}"
