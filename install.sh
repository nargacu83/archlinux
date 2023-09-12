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
CHROOT_INSTALL_DIRECTORY="/mnt/install"
CONFIG_DIRECTORY="${CURRENT_DIRECTORY}/config"
LOGS_DIRECTORY="${CURRENT_DIRECTORY}/logs"
SCRIPTS_DIRECTORY="${CURRENT_DIRECTORY}/scripts"
MULTIPLE_LOG_FILES=0
errors=()

# Initialize configuration variables
INSTALL_AUR=1
INSTALL_FLATPAKS=1
ENABLE_MULTILIB=1
INSTALL_FSTAB=1
# If parallel_downloads is greater than 0, it will be set otherwise ignored
parallel_downloads=0
FSTAB=()

function print_message() {
    echo -e "${BOLD}${GREEN} ==> ${NC} ${BOLD}${1}${NORMAL}"
    log "${2}==> ${1}"
}

function print_inner_message() {
    echo -e "${BOLD}${BLUE} ->${NC} ${BOLD}${1}${NORMAL}"
    log " -> ${1}"
}

function print_error() {
    echo -e "${BOLD}${RED} ->${NC} ${BOLD}${1}${NORMAL}"
    log " -> ${1}"
    exit 1
}

function log() {
  [[ -d ${LOGS_DIRECTORY} ]] || mkdir ${LOGS_DIRECTORY}

  count=0
  logfile="install.${count}.log"

  # Use multiple log files
  if [ ${MULTIPLE_LOG_FILES} -eq 1 ]; then
    # log file already exists
    if [ -f "${LOGS_DIRECTORY}/${logfile}" ]; then
      # get it's new possible name
      while [ -f "${LOGS_DIRECTORY}/${logfile}" ]; do
          count=$(($count + 1))
          logfile="install.${count}.log"
      done

      # rename the existing file
      mv "${LOGS_DIRECTORY}/install.0.log" "${LOGS_DIRECTORY}/install.${count}.log"

      # reset the name
      count=0
      logfile="install.${count}.log"
    fi
  fi

  echo "${1}" >> "${LOGS_DIRECTORY}/${logfile}"
}

function chroot_cmd() {
  arch-chroot /mnt "$@"
}

function chroot_function() {
	cp ${0} /mnt/root
	chmod 755 /mnt/root/$(basename "${0}")
	arch-chroot /mnt /root/$(basename "${0}") --chroot ${1} ${2}
	rm /mnt/root/$(basename "${0}")
}

function chroot_sudo_cmd() {
  arch-chroot /mnt sudo -u ${username} "$@"
}

function chroot_user_enter() {
  arch-chroot /mnt su ${username}
}

function check_config() {
  # Get all config files
  configs=()
  for file in "${CONFIG_DIRECTORY}"/*; do
      configs+=($(basename $file))
  done

  # Check if there are config files
  if [ ${#configs[@]} -eq 0 ]; then
    print_error "No configs detected"
    exit 1
  fi

  # Check if selected config was not given
  if [ "$SELECTED_CONFIG" == "" ]; then
    SELECTED_CONFIG="default"
  fi

  # Check if the given configuration file name exists
  valid=0
  for config in "${configs[@]}"; do
    if [ "$SELECTED_CONFIG" == "$config" ]; then
      valid=1
    fi
  done
  if [ $valid -eq 0 ]; then
    print_error "Configuration file \"$SELECTED_CONFIG\" not found"
    exit 1
  fi
}

usage()
{
    echo "Usage: $0 [args]"
    echo "Args:"
    echo "--config <config_name>"
    echo "--no-flatpak"
    echo "--no-aur"
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
      SELECTED_CONFIG=${args[$(($i + 1))]}
      ;;
    --no-flatpak)
      INSTALL_FLATPAK=0
      ;;
    --no-aur)
      INSTALL_AUR=0
      ;;
    --no-multilib)
      ENABLE_MULTILIB=0
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

# Import the seleted configuration
source "${CONFIG_DIRECTORY}/${SELECTED_CONFIG}"

# Install base
source "${SCRIPTS_DIRECTORY}/_create_partitions"
source "${SCRIPTS_DIRECTORY}/_install_base"
source "${SCRIPTS_DIRECTORY}/_create_user"
source "${SCRIPTS_DIRECTORY}/_install_bootloader"
