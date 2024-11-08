#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[1;34m'  # Changed to light blue
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
echo -e "Welcome to the Swetrix configuration tool!"
echo -e "This utility helps you set up your Swetrix environment by configuring essential parameters"
echo -e "and generating secure credentials for your installation to get you started as quickly as possible.\n"

# Function to generate a random string
generate_random_string() {
  openssl rand -base64 64 | tr -d '/+=' | cut -c1-64
}

# Check if .env exists
if [ -f .env ]; then
  echo -e "${YELLOW}Warning: .env file already exists!${NC}"
  read -p "Do you want to continue and overwrite it? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
  fi
fi

# Create/overwrite .env file
echo -e "${GREEN}Creating new .env file...${NC}"

echo -e "# Swetrix Frontend configuration" > .env

# API_URL
while true; do
	echo
  read -p "Enter API_URL of your Swetrix API instance (required, e.g., https://api.swetrix.example.com): " api_url
  if [ -n "$api_url" ]; then
    echo "API_URL=$api_url" >> .env
    break
  else
    echo -e "${RED}API_URL is required. Please enter a value.${NC}"
  fi
done

echo -e "\n# Swetrix API configuration" >> .env

# JWT tokens
echo
read -p "Enter JWT_ACCESS_TOKEN_SECRET (press Enter to auto-generate): " jwt_access
if [ -z "$jwt_access" ]; then
  jwt_access=$(generate_random_string)
  echo -e "${GREEN}Generated JWT_ACCESS_TOKEN_SECRET${NC}"
fi
echo "JWT_ACCESS_TOKEN_SECRET=$jwt_access" >> .env

echo
read -p "Enter JWT_REFRESH_TOKEN_SECRET (press Enter to auto-generate): " jwt_refresh
if [ -z "$jwt_refresh" ]; then
  jwt_refresh=$(generate_random_string)
  echo -e "${GREEN}Generated JWT_REFRESH_TOKEN_SECRET${NC}"
fi
echo "JWT_REFRESH_TOKEN_SECRET=$jwt_refresh" >> .env

# Email
while true; do
  echo
  read -p "Enter admin EMAIL (required): " email
  if [ -n "$email" ]; then
    echo "EMAIL=$email" >> .env
    break
  else
    echo -e "${RED}Email is required. Please enter a value.${NC}"
  fi
done

# Password
while true; do
  echo
  read -s -p "Enter admin PASSWORD (required, min 8 characters): " password
  echo
  if [ ${#password} -ge 8 ]; then
    echo "PASSWORD=$password" >> .env
    break
  else
    echo -e "${RED}Password must be at least 8 characters long.${NC}"
  fi
done

# Cloudflare proxy
echo
read -p "Enable Cloudflare proxy? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "CLOUDFLARE_PROXY_ENABLED=true" >> .env
else
  echo "CLOUDFLARE_PROXY_ENABLED=false" >> .env
fi

# Debug mode (always false)
echo "DEBUG_MODE=false" >> .env
echo "API_KEY=" >> .env
echo "IP_GEOLOCATION_DB_PATH=" >> .env

echo -e "\n\n# Keep these empty unless you manually set passwords for your databases" >> .env
echo "REDIS_PASSWORD=" >> .env
echo "CLICKHOUSE_PASSWORD=" >> .env

echo -e "\n${GREEN}Configuration complete! .env file has been created.${NC}"
echo -e "${YELLOW}Note: Make sure to review the .env file before starting the application.${NC}"
