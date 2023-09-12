#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
# Styles
NC='\033[0m' # No Color
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

# Global variables
CURRENT_DIRECTORY="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

INSTALL_DIRECTORY="${CURRENT_DIRECTORY}/install"
config_directory="${CURRENT_DIRECTORY}/config"
LOGS_DIRECTORY="${CURRENT_DIRECTORY}/logs"
scripts_directory="${CURRENT_DIRECTORY}/scripts"
errors=()

# Initialize configuration variables
enable_multilib=1
enable_fstab=1
# If parallel_downloads is greater than 0, it will be set otherwise ignored
timezone="Europe/Paris"
parallel_downloads=0
fstab=()

function print_message() {
    echo -e "${BOLD}${GREEN} ==> ${NC} ${BOLD}${1}${NORMAL}"
}

function print_inner_message() {
    echo -e "${BOLD}${BLUE} ->${NC} ${BOLD}${1}${NORMAL}"
}

function print_error() {
    echo -e "${BOLD}${RED} ->${NC} ${BOLD}${1}${NORMAL}"
    exit 1
}

function check_config() {
  # Get all config files
  configs=()
  for file in "${config_directory}"/*; do
      configs+=($(basename $file))
  done

  # Check if there are config files
  if [ ${#configs[@]} -eq 0 ]; then
    print_error "No configs detected"
    exit 1
  fi

  # Check if selected config was not given
  if [ "$selected_config" == "" ]; then
    selected_config="default"
  fi

  # Check if the given configuration file name exists
  valid=0
  for config in "${configs[@]}"; do
    if [ "$selected_config" == "$config" ]; then
      valid=1
    fi
  done
  if [ $valid -eq 0 ]; then
    print_error "Configuration file \"$selected_config\" not found"
    exit 1
  fi
}

usage()
{
    echo "Usage: $0 [args]"
    echo "Args:"
    echo "--config <config_name>"
    echo "--no-multilib"
    echo "--parallel-downloads <amount>"
}

args=()
while [ "${1:-}" != "" ]; do
  args+=("${1:-}")
  shift
done

for i in "${!args[@]}"; do
  arg=${args[$i]}
  case $arg in
    --config)
      selected_config=${args[$(($i + 1))]}
      ;;
    --no-multilib)
      enable_multilib=0
      ;;
    --parallel-downloads)
      parallel_downloads=${args[$(($i + 1))]}
      if ! [[ $parallel_downloads =~ '^[0-9]+$' ]] ; then
        parallel_downloads=0
        print_error "Invalid argument value for parallel_downloads"
        exit 1
      fi
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done


check_config

# Import the selected configuration
source "${config_directory}/${selected_config}"

# Install base
source "${scripts_directory}/_create_partitions"
source "${scripts_directory}/_install_base"

# Continue installation in chroot
# Copy chroot script
cp ./scripts/_chroot_install /mnt/root
# Copy the config for the chroot script
cp ${config_directory}/${selected_config} /mnt/root/_config
chmod 755 /mnt/root/_chroot_install

# Execute entry point
arch-chroot /mnt /root/_chroot_install

# Removes scripts once done
rm /mnt/root/_config
rm /mnt/root/_chroot_install
