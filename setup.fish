#!/usr/bin/fish

function handle_sigint
    echo "=== Setup cancelled. ==="
    exit 0
end

function print
    echo -e "\e[45m$argv[1]\e[0m"
end

function download
    if test (count $argv) -ne 2
        print "Download function received not exact 2 params!"
        exit 1
    end
    curl -fsSL --create-dirs $argv[1] -o $argv[2]
end

function download_sudo
    if test (count $argv) -ne 2
        print "Download function received not exact 2 params!"
        exit 1
    end
    sudo curl -fsSL --create-dirs $argv[1] -o $argv[2]
end

function download_extract
    if test (count $argv) -ne 2
        print "Download function received not exact 2 params!"
        exit 1
    end
    mkdir -p $argv[2]
    curl -fsSL $argv[1] | tar xfz - -C $argv[2]
end

function execute
    if test (count $argv) -ne 1
        print "Execute function received not exact 1 param!"
        exit 1
    end
    curl -fsSL $argv[1] | sh
end

trap handle_sigint SIGINT

if not test -e "$HOME/.env"
    touch "$HOME/.env"
end
if not test -e "$HOME/.path_vars"
    touch "$HOME/.path_vars"
end

# enable IPv6 privacy extensions: https://wiki.archlinux.org/title/IPv6#Privacy_extensions
if test (grep -zoP "# Enable IPv6 Privacy Extensions\nnet.ipv6.conf.all.use_tempaddr = 2\nnet.ipv6.conf.default.use_tempaddr = 2" /etc/sysctl.d/40-ipv6.conf | wc -l) -ne 2
    print "=== Configuring IPv6 privacy extensions"
    echo "# Enable IPv6 Privacy Extensions
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2" | sudo tee -a /etc/sysctl.d/40-ipv6.conf > /dev/null
end

# 'ls' alternative: https://lla.chaqchase.com/docs/about/introduction
if not command -v lla > /dev/null
    print "=== Installing lla as 'ls' alternative... ==="
    execute https://raw.githubusercontent.com/chaqchase/lla/main/install.sh
end
if not test -e ~/.config/lla/config.toml
    print "=== Installing lla configuration... ==="
    download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/lla/config.toml ~/.config/lla/config.toml
end

# cool resources monitor: https://github.com/aristocratos/btop
if not command -v btop > /dev/null
    print "=== Installing btop... ==="
    sudo pacman -S btop
end
if not test -e ~/.config/btop/btop.conf
    print "=== Installing btop configuration... ==="
    download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/btop/btop.conf ~/.config/btop/btop.conf
end

# package manager: https://github.com/Jguer/yay
if not command -v yay > /dev/null
    print "=== Installing yay from source... ==="
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git "$HOME/Dokumente/yay"
    cd "$HOME/Dokumente/yay"
    makepkg -si
end

if not pacman -Q ttf-twemoji-color > /dev/null 2>&1
    print "=== Installing emoji font to fix rendering issues... ==="
    yay ttf-twemoji-color
end

# default browser: https://librewolf.net
if not command -v librewolf > /dev/null
    print "=== Installing librewolf... ==="
    yay librewolf-bin
end
if not test -e ~/.librewolf/librewolf.overrides.cfg
    print "=== Installing custom librewolf configuration... ==="
else
    print "=== Updating custom librewolf configuration... ==="
end
download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/browser/librewolf.overrides.cfg ~/.librewolf/librewolf.overrides.cfg

# backup browser: https://vivaldi.com
if not command -v vivaldi > /dev/null
    print "=== Installing Vivaldi... ==="
    sudo pacman -S vivaldi
end

# default editor: https://vscodium.com
if not command -v codium > /dev/null
    print "=== Installing codium... ==="
    yay vscodium-bin
end
print "=== Installing codium extensions... ==="
# Save currently installed extensions with:
# codium --list-extensions > vscodium/extensions.txt
curl -fsSL https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/vscodium/extensions.txt | xargs -L 1 codium --install-extension

# Arch Linux update helper: https://github.com/Antiz96/arch-update
if not command -v arch-update > /dev/null
    print "=== Installing and configuring arch-update... ==="
    yay arch-update
    download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/arch-update/arch-update.conf ~/.config/arch-update/arch-update.conf
    arch-update --tray --enable
    systemctl --user enable --now arch-update.timer
end

# GitHub cli tool: https://cli.github.com/
if not command -v gh > /dev/null
    print "=== Installing and setting up GitHub CLI... ==="
    sudo pacman -S github-cli
    gh auth login
end

# fast & modern Python package manager: https://docs.astral.sh/uv/
if not command -v uv > /dev/null
    print "=== Installing uv... ==="
    execute https://astral.sh/uv/install.sh
    set just_installed 1
end
if test "$just_installed" != 1
    print "=== Self-updating uv... ==="
    uv self update
end

# automatically purge old files from trash: https://github.com/bneijt/autotrash
if not command -v autotrash > /dev/null
    print "=== Installing and configuring autotrash... ==="
    uv tool install autotrash
    autotrash -d 40 --install
end

# Linux onedrive sync client: https://github.com/abraunegg/onedrive
if not command -v onedrive > /dev/null
    print "=== Installing onedrive client... ==="
    yay onedrive-abraunegg
    sudo mkdir /var/log/onedrive
    sudo chown root:(whoami) /var/log/onedrive
    sudo chmod 0775 /var/log/onedrive
end

# well, it's Docker
if not command -v docker > /dev/null
    print "=== Installing rootless Docker... ==="
    download "$HOME/.config/docker/daemon.json" https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/docker/daemon.json
    execute https://get.docker.com/rootless
    set path_vars "$HOME/.path_vars"
    set docker_bin_path "$HOME/bin"
    if not grep -q $docker_bin_path $path_vars
        echo $docker_bin_path >> $path_vars
    end
    set env_path "$HOME/.env"
    set docker_host "DOCKER_HOST=unix:///run/user/1000/docker.sock"
    if not grep -q $docker_host $env_path
        echo $docker_host >> $env_path
    end
end

# required for AppImages
if not pacman -Q | grep -q fuse2
    print "=== Installing fuse2 to be able to use AppImages... ==="
    sudo pacman -S fuse
end

# Bruno (HTTP client): https://usebruno.com
if not command -v bruno > /dev/null
    print "=== Installing Bruno... ==="
    yay bruno-bin
end

# Gimp: https://www.gimp.org
if not command -v gimp > /dev/null
    print "=== Installing Gimp... ==="
    sudo pacman -S gimp
end

# JetBrains toolbox for JetBrains IDEs: https://www.jetbrains.com/toolbox-app/
# Installer: https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/jetbrains-toolbox.sh
# Installer based on: https://github.com/nagygergo/jetbrains-toolbox-install
if not test -d "$HOME/.local/share/JetBrains/Toolbox/bin"
    print "=== Installing JetBrains toolbox... ==="
    execute https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/jetbrains-toolbox.sh
end

# universal video downloader tool: https://github.com/yt-dlp/yt-dlp
if not command -v yt-dlp > /dev/null
    print "=== Installing yt-dlp... ==="
    download_sudo https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp /usr/local/bin/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
end

if sudo dmidecode -s system-manufacturer | grep -qi "Tuxedo"
    # TUXEDO specific tools and drivers
    set packages (pacman -Q | grep tuxedo | count)
    if test $packages -ne 3
        print "=== Tuxedo detected - Installing tools and drivers... ==="
        yay tuxedo-control-center-bin tuxedo-drivers-dkms tuxedo-webfai-creator-bin
    end
    if not test -f ~/Dokumente/tuxedo/TCC_Profiles_Backup.json
        print "=== Tuxedo - Fetching control center profiles... ==="
        download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/tuxedo/TCC_Profiles_Backup.json ~/Dokumente/tuxedo/TCC_Profiles_Backup.json
    end
else
    # Not on laptop

    # device manager for Logitech devices: https://github.com/pwr-Solaar/Solaar
    if not command -v solaar > /dev/null
        print "=== Installing solaar... ==="
        sudo pacman -S solaar
    end
    # configure autostart
    download_sudo https://raw.githubusercontent.com/pwr-Solaar/Solaar/refs/heads/master/share/autostart/solaar.desktop /etc/xdg/autostart/solaar.desktop
    # give permissions
    download_sudo https://raw.githubusercontent.com/pwr-Solaar/Solaar/master/rules.d-uinput/42-logitech-unify-permissions.rules /etc/udev/rules.d/42-logitech-unify-permissions.rules
    # update rules
    download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/solaar/rules.yaml ~/.config/solaar/rules.yaml
    sudo udevadm control --reload-rules
    # video editor: https://kdenlive.org
    if not command -v kdenlive > /dev/null
        print "=== Installing kdenlive... ==="
        yay kdenlive
    end
end

# well, it's Signal
if not command -v signal-desktop > /dev/null
    print "=== Installing Signal Desktop... ==="
    yay signal-desktop
end

# well, it's Element
if not command -v element-desktop > /dev/null
    print "=== Installing Element Desktop... ==="
    yay element-desktop
end

# disk usage analyzer tool
if not command -v ncdu > /dev/null
    print "=== Installing ncdu... ==="
    sudo pacman -S ncdu
end

# helper to install Proton versions
if not command -v protonplus > /dev/null
    print "=== Installing protonplus... ==="
    yay protonplus
end

# install KDE window open/close effects: https://github.com/Schneegans/Burn-My-Windows
print "=== Installing KDE window open/close effects... ==="
download_extract https://github.com/Schneegans/Burn-My-Windows/releases/latest/download/burn_my_windows_kwin6.tar.gz ~/.local/share/kwin/effects

# rerate CachyOS mirrors
if test -e "$HOME/.cachymirrors"
    set reference_point (date -d "-3 weeks" +%s)
    set checkpoint (cat "$HOME/.cachymirrors")
    if test $reference_point -lt $checkpoint
        print "=== Setup finished :) ==="
        exit 0
    end
end
print "=== Rating CachyOS mirrors... ==="
sudo cachyos-rate-mirrors
set current_stamp (date +%s)
echo $current_stamp > "$HOME/.cachymirrors"
print "=== Setup finished :) ==="
