#!/usr/bin/env bash

# Script to install your software package

set -e  # Exit immediately if a command exits with non-zero status

# Print colorful messages
echo_info() {
  echo -e "\033[0;34m$1\033[0m"  # Blue text
}

echo_success() {
  echo -e "\033[0;32m$1\033[0m"  # Green text
}

echo_error() {
  echo -e "\033[0;31m$1\033[0m"  # Red text
}

# Check for required dependencies
check_dependencies() {
  echo_info "Checking for required dependencies..."
  
  for cmd in npm docker git; do
    if ! command -v $cmd &> /dev/null; then
      echo_error "Error: $cmd is required but not installed. Please install it and try again."
      exit 1
    fi
  done
}

# Clean function (previously in clean.sh)
clean_environment() {
  echo_info "Cleaning previous installation..."
  
  ROOT=$(pwd)
  
  # Reset git repository
  if [ ! -d "$ROOT/core" ]; then
    git clone https://github.com/citrineos/citrineos-core.git core
  fi

  cd "$ROOT/core/Server"
  echo_info "Stopping and removing Docker containers..."
  docker compose down && docker compose rm -f && docker ps -aq --filter "label=com.docker.compose.project=$(basename $(pwd))" | xargs docker rm -f && docker compose down --volumes && docker images --filter "reference=$(basename $(pwd))*" -q | xargs docker rmi
  
  cd "$ROOT/core"
  pwd
  echo_info "Resetting git repository..."
  git reset --hard
  git clean -xfd
  git status
  cd "$ROOT"
}

get_file() {
  local local_path="$1"
  local github_path="$2"
  local dir_path=$(dirname "$local_path")
  
  # Create directory if it doesn't exist
  mkdir -p "$dir_path"
  
  if [ -f "$local_path" ]; then
    echo_info "Using local file: $local_path"
  else
    echo_info "Downloading file from GitHub: $github_path"
    curl -s -L "$github_path" -o "$local_path"
    if [ $? -ne 0 ]; then
      echo_error "Failed to download file from GitHub: $github_path"
      exit 1
    fi
  fi
}

install_app() {
  ROOT=$(pwd)
  cd $ROOT/core
  echo_info "Installing dependencies..."
  npm run install-all
  
  echo_info "Building the application..."
  npm run build
  
  echo_info "Setting up Docker environment..."
  # Create directories
  mkdir -p "$ROOT/core/Server/src"
  
  # Get Dockerfile
  get_file "$ROOT/Docker/core/Dockerfile" "https://raw.githubusercontent.com/aasanchez/Citrine/main/Docker/core/Dockerfile"
  get_file "$ROOT/Docker/core/install-postgis.sh" "https://raw.githubusercontent.com/aasanchez/Citrine/main/Docker/core/install-postgis.sh"
  get_file "$ROOT/Docker/core/docker-compose.yml" "https://raw.githubusercontent.com/aasanchez/Citrine/main/Docker/core/docker-compose.yml"
  
  # Copy files to the correct locations
  cp "$ROOT/Docker/core/Dockerfile" "$ROOT/core/Server/src/Dockerfile"
  cp "$ROOT/Docker/core/install-postgis.sh" "$ROOT/core/Server/src/install-postgis.sh"
  cp "$ROOT/Docker/core/docker-compose.yml" "$ROOT/core/Server/docker-compose.yml"
  
  echo_info "Starting Docker containers..."
  cd "$ROOT/core/Server" || { echo_error "Failed to change directory"; exit 1; }
  docker compose -f ./docker-compose.yml up -d
  
  echo_info "Starting application..."
  npm start
}

# Main execution
echo_info "Starting installation process..."
check_dependencies
clean_environment
install_app
# echo_success "Installation completed successfully!"
