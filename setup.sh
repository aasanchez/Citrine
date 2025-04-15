#!/usr/bin/env bash

# Script to install your software package
# Usage: curl http://yourserver.com/mypackage.sh | bash

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
  
  # Clean Docker containers and images
  cd "$ROOT/core/Server" 2>/dev/null || {
    echo_info "No existing Server directory found, skipping Docker cleanup..."
    return 0
  }
  
  echo_info "Stopping and removing Docker containers..."
  docker compose down 2>/dev/null || true
  docker compose rm -f 2>/dev/null || true
  docker ps -aq --filter "label=com.docker.compose.project=$(basename $(pwd))" | xargs docker rm -f 2>/dev/null || true
  docker compose down --volumes 2>/dev/null || true
  docker images --filter "reference=$(basename $(pwd))*" -q | xargs docker rmi 2>/dev/null || true
  
  # Reset git repository
  cd "$ROOT/core" 2>/dev/null || {
    echo_info "No existing core directory found, skipping git cleanup..."
    return 0
  }
  
  echo_info "Resetting git repository..."
  git status
  git reset --hard
  git clean -xfd
  
  cd "$ROOT" || exit 1
}

# Main installation function
install_app() {
  ROOT=$(pwd)
  
  echo_info "Installing dependencies..."
  npm run install-all
  
  echo_info "Building the application..."
  npm run build
  
  echo_info "Setting up Docker environment..."
  # Fix the problems with postgis on Mac
  mkdir -p "$ROOT/core/Server/src" "$ROOT/core/Server"
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
# install_app
# echo_success "Installation completed successfully!"