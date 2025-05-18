#!/usr/bin/fish

function handle_sigint
    echo "=== Setup cancelled. ==="
    exit 0
end

function print
    echo -e "\e[45m$argv[1]\e[0m"
end

trap handle_sigint SIGINT

if not test -e "$HOME/.env"
    touch "$HOME/.env"
end
if not test -e "$HOME/.path_vars"
    touch "$HOME/.path_vars"
end

# 'ls' alternative: https://lla.chaqchase.com/docs/about/introduction
if not command -v lla > /dev/null
    print "=== Installing lla as 'ls' alternative... ==="
    curl -fsSL https://raw.githubusercontent.com/chaqchase/lla/main/install.sh | sh
end

# cool resources monitor: https://github.com/aristocratos/btop
if not command -v btop > /dev/null
    print "=== Installing btop... ==="
    sudo pacman -S btop
end
if not test -e ~/.config/btop/btop.conf
    print "=== Installing btop configuration... ==="
    if not test -d ~/.config/btop
        mkdir ~/.config/btop
    end
    curl -fsSL https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/btop.conf -o ~/.config/btop/btop.conf
end

# package manager: https://github.com/Jguer/yay
if not command -v yay > /dev/null
    print "=== Installing yay from source... ==="
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git "$HOME/Dokumente/yay"
    cd "$HOME/Dokumente/yay"
    makepkg -si
end

# default browser: https://librewolf.net
if not command -v librewolf > /dev/null
    print "=== Installing librewolf... ==="
    yay -S librewolf-bin
end
if not test -d ~/.librewolf
    mkdir ~/.librewolf
end
if not test -e ~/.librewolf/librewolf.overrides.cfg
    print "=== Installing custom librewolf configuration... ==="
else
    print "=== Updating custom librewolf configuration... ==="
end
curl -fsSL https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/browser/librewolf.overrides.cfg -o ~/.librewolf/librewolf.overrides.cfg

# backup browser: https://vivaldi.com
if not command -v vivaldi > /dev/null
    print "=== Installing Vivaldi... ==="
    sudo pacman -S vivaldi
end

# default editor: https://vscodium.com
if not command -v codium > /dev/null
    print "=== Installing codium... ==="
    yay -S vscodium-bin
end
print "=== Installing codium extensions... ==="
# Save currently installed extensions with:
# codium --list-extensions > vscodium/extensions.txt
curl -fsSL https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/vscodium/extensions.txt | xargs -L 1 codium --install-extension

# GitHub cli tool: https://cli.github.com/
if not command -v gh > /dev/null
    print "=== Installing and setting up GitHub CLI... ==="
    sudo pacman -S github-cli
    gh auth login
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
    yay -S onedrive-abraunegg
    sudo mkdir /var/log/onedrive
    sudo chown root:(whoami) /var/log/onedrive
    sudo chmod 0775 /var/log/onedrive
end

# fast & modern Python package manager: https://docs.astral.sh/uv/
if not command -v uv > /dev/null
    print "=== Installing uv... ==="
    curl -fsSL https://astral.sh/uv/install.sh | sh
end

# well, it's Docker
if not command -v docker > /dev/null
    print "=== Installing rootless Docker... ==="
    curl --create-dirs -fsSLo "$HOME/.config/docker/daemon.json" https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/docker/daemon.json
    curl -fsSL https://get.docker.com/rootless | sh
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

# JetBrains toolbox for JetBrains IDEs: https://www.jetbrains.com/toolbox-app/
# Installer: https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/jetbrains-toolbox.sh
# Installer based on: https://github.com/nagygergo/jetbrains-toolbox-install
if not test -d "$HOME/.local/share/JetBrains/Toolbox/bin"
    print "=== Installing JetBrains toolbox... ==="
    curl -fsSL https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/jetbrains-toolbox.sh | sh
end

# universal video downloader tool: https://github.com/yt-dlp/yt-dlp
if not command -v yt-dlp > /dev/null
    print "=== Installing yt-dlp... ==="
    sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
end

if sudo dmidecode -s system-manufacturer | grep -qi "Tuxedo"
    # TUXEDO specific tools and drivers
    set packages (pacman -Q | grep tuxedo | count)
    if test $packages -ne 3
        print "=== Tuxedo detected - Installing tools and drivers... ==="
        yay -S tuxedo-control-center-bin tuxedo-drivers-dkms tuxedo-webfai-creator-bin
    end
    if not test -d ~/Dokumente/tuxedo
        mkdir ~/Dokumente/tuxedo
    end
    if not test -f ~/Dokumente/tuxedo/TCC_Profiles_Backup.json
        print "=== Tuxedo - Fetching control center profiles... ==="
        curl -fsSL https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/tuxedo/TCC_Profiles_Backup.json -o ~/Dokumente/tuxedo/TCC_Profiles_Backup.json
    end
else
    # Not on laptopk
    # video editor: https://kdenlive.org
    if not command -v kdenlive > /dev/null
        print "=== Installing kdenlive... ==="
        yay -S kdenlive
    end
end

# well, it's Signal
if not command -v signal-desktop > /dev/null
    print "=== Installing Signal Desktop... ==="
    yay -S signal-desktop
end

# well, it's Element
if not command -v element-desktop > /dev/null
    print "=== Installing Element Desktop... ==="
    yay -S element-desktop
end

# disk usage analyzer tool
if not command -v ncdu > /dev/null
    print "=== Installing ncdu... ==="
    sudo pacman -S ncdu
end

# enable IPv6 privacy extensions: https://wiki.archlinux.org/title/IPv6#Privacy_extensions
if test (grep -zoP "# Enable IPv6 Privacy Extensions\nnet.ipv6.conf.all.use_tempaddr = 2\nnet.ipv6.conf.default.use_tempaddr = 2" /etc/sysctl.d/40-ipv6.conf | wc -l) -ne 2
    print "=== Configuring IPv6 privacy extensions"
    echo "# Enable IPv6 Privacy Extensions
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2" | sudo tee -a /etc/sysctl.d/40-ipv6.conf > /dev/null
end

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
