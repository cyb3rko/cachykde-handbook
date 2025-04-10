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

if not command -v lla > /dev/null
    print "=== Installing lla as 'ls' alternative... ==="
    curl -fsSL https://raw.githubusercontent.com/chaqchase/lla/main/install.sh | sh
end

if not command -v ncdu > /dev/null
    print "=== Installing ncdu... ==="
    sudo pacman -S ncdu
end

if not command -v yay > /dev/null
    print "=== Installing yay from source... ==="
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git "$HOME/Dokumente/yay"
    cd "$HOME/Dokumente/yay"
    makepkg -si
end

if not command -v uv > /dev/null
    print "=== Installing uv... ==="
    curl -fsSL https://astral.sh/uv/install.sh | sh
end

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

if not command -v autotrash > /dev/null
    print "=== Installing and configuring autotrash... ==="
    uv tool install autotrash
    autotrash -d 40 --install
end

if not command -v onedrive > /dev/null
    print "=== Installing onedrive client... ==="
    yay -S onedrive-abraunegg
    sudo mkdir /var/log/onedrive
    sudo chown root:(whoami) /var/log/onedrive
    sudo chmod 0775 /var/log/onedrive
end

if not command -v codium > /dev/null
    print "=== Installing codium... ==="
    yay -S vscodium-bin
end

if not command -v gh > /dev/null
    print "=== Installing and setting up GitHub CLI... ==="
    sudo pacman -S github-cli
    gh auth login
end

if not pacman -Q | grep -q fuse2
    print "=== Installing fuse2 to be able to use AppImages... ==="
    sudo pacman -S fuse
end

if not test -d "$HOME/.local/share/JetBrains/Toolbox/bin"
    print "=== Installing JetBrains toolbox... ==="
    curl -fsSL https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/jetbrains-toolbox.sh | sh
end

if not command -v yt-dlp > /dev/null
    print "=== Installing yt-dlp... ==="
    sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
end

if sudo dmidecode -s system-manufacturer | grep -qi "Tuxedo"
    set packages (pacman -Q | grep tuxedo | count)
    if test $packages -ne 3
        print "=== Tuxedo detected - Installing tools and drivers... ==="
        yay -S tuxedo-control-center-bin tuxedo-drivers-dkms tuxedo-webfai-creator-bin
    end
end

if not command -v signal-desktop > /dev/null
    print "=== Installing Signal Desktop... ==="
    yay -S signal-desktop
end

if not command -v element-desktop > /dev/null
    print "=== Installing Element Desktop... ==="
    yay -S element-desktop
end

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
