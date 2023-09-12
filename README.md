# ArchLinux installation scripts

A simple ArchLinux installation script.

## How to use

1. Clone the repository
    
    `git clone https://github.com/nargacu83/archlinux`.

2. Configure
    
    `cp ./config/default ./config/my_config`.
    
3. Install

    `./install --config my_config`

    You can also install ArchLinux with your dotfiles `./install --config my_config --dotfiles`

## Configuration

You can check your configuration by using the command `install --check --config my_config`.

## Advanced configuration

You can create your own scripts in `./scripts/custom/` and register it in your configuration.

## Credits

Mageas for his bloated scripts.
