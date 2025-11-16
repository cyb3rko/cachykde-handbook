#!/usr/bin/fish

function handle_sigint
  echo "=== Setup cancelled. ==="
  exit 0
end

function print
  echo -e "\e[45m$argv[1]\e[0m"
end

function is_command
  command -v $argv[1] > /dev/null
end

function is_function
  functions -q $argv[1]
end

function is_customized
  test -e $argv[1] && test (head -n 1 $argv[1]) = "# custom"
end

function last_chars
  if test (count $argv) -ne 2
    echo "Last_chars function received not exact 2 params!"
    exit 1
  end
  echo (string sub -s (math (string length $argv[2]) - 1) -l $argv[1] $argv[2])
end

function install
  if test (count $argv) -ne 1
    print "Install function received not exact 1 param!"
    exit 1
  end
  paru $argv[1]
end

function install_repo
  if test (count $argv) -ne 1
    print "Install_repo function received not exact 1 param!"
    exit 1
  end
  paru --repo $argv[1]
end

function uninstall
  if test (count $argv) -ne 1
    print "Uninstall function received not exact 1 param!"
    exit 1
  end
  paru -Rc --noconfirm $argv[1]
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
  # xz
  if test (last_chars 2 $argv[1]) = "xz"
    curl -fsSL $argv[1] | tar xfJ - -C $argv[2]
  # gzip
  else if test (last_chars 2 $argv[1]) = "gz"
    curl -fsSL $argv[1] | tar xfz - -C $argv[2]
  # zip
  else if test (last_chars 3 $argv[1]) = "zip"
    curl -fsSL $argv[1] | unzip - -d $argv[2]
  # unknown
  else
    print "Download function received unexpected archive type!"
    exit 1
  end
end

function fetch
  if test (count $argv) -ne 1
    print "Fetch function received not exact 1 param!"
    exit 1
  end
  for line in $(curl -fsSL $argv[1])
    echo $line
  end
end

function execute
  if test (count $argv) -ne 1
    print "Execute function received not exact 1 param!"
    exit 1
  end
  fetch $argv[1] | sh
end

# function to replace content in file:
#   replace file.txt "current_content" "new_content"
function replace
  if test (count $argv) -ne 3
    print "Replace function received not exact 3 params!"
    exit 1
  end
  sed -i "s/$argv[2]/$argv[3]/g" $argv[1]
end

trap handle_sigint SIGINT

# lock down root user
print "=== Locking down root... ==="
sudo passwd --lock root

# configure ufw (Firewall) defaults
print "=== Configuring ufw (Firewall)... ==="
echo "y" | sudo ufw reset | grep -v "WARN: "
sudo ufw default deny incoming | grep -v "^(be sure to"
sudo ufw default allow outgoing | grep -v "^(be sure to"
sudo ufw default deny routed | grep -v "^(be sure to"

# configure ufw rules for KDE Connect
sudo ufw allow 1714:1764/udp
sudo ufw allow 1714:1764/tcp
sudo ufw enable

if not test -e ~/.env
  touch ~/.env
end
if not test -e ~/.path_vars
  touch ~/.path_vars
end

if not is_customized ~/.config/git/config
  print "=== Configuring .git config... ==="
  download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/git/config ~/.config/git/config
end

# remove unused files and dirs
rm -rf -- ~/.bash_history ~/.bash_logout ~/.gitconfig ~/.zshrc ~/Musik ~/Öffentlich ~/Vorlagen

# initialize fish config if never done before
if not is_customized ~/.config/fish/config.fish
  print "=== Detected fish config in initial state, overwriting with custom config... ==="
  cp ~/.config/fish/config.fish ~/.config/fish/config.fish.backup
  download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/fish/config.fish ~/.config/fish/config.fish
  source ~/.config/fish/config.fish
end

# package manager and AUR helper: https://github.com/Morganamilo/paru
if not is_command paru
  print "=== Installing paru...  ==="
  sudo pacman -S --noconfirm paru
end

if is_command yay
  print "=== Uninstalling yay and cleaning up yay cache...  ==="
  if pacman -Qs yay-bin > /dev/null
    uninstall yay-bin
  else
    uninstall yay
  end
  rm -rf -- ~/.cache/yay
end

if not is_command flatpak
  print "=== Installing flatpak...  ==="
  install_repo flatpak
end

print "=== Removing unused snaps...  ==="
snap list --all | awk '/disabled/{print $1" --revision "$3}' | xargs -rn3 sudo snap remove

# 'ls' alternative: https://lla.chaqchase.com/docs/about/introduction
if not is_command lla
  print "=== Installing lla as 'ls' alternative... ==="
  execute https://raw.githubusercontent.com/chaqchase/lla/main/install.sh
end
if not test -e ~/.config/lla/config.toml
  print "=== Installing lla configuration... ==="
  download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/lla/config.toml ~/.config/lla/config.toml
end

# 'cat' clone: https://github.com/sharkdp/bat
if not test -e ~/.config/bat/config
  print "=== Installing bat configuration... ==="
  download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/bat/config ~/.config/bat/config
end

# combined tracert and ping tool: https://github.com/traviscross/mtr
# (for manual usage and required for zoom testing)
if not is_command mtr
  print "=== Installing mtr... ==="
  install_repo mtr
end

# open-source antivirus engine: https://www.clamav.net
if not is_command clamd
  print "=== Installing ClamAV... ==="
  install_repo clamav
  download_sudo https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/clamav/clamd.conf /etc/clamav/clamd.conf
  download_sudo https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/clamav/freshclam.conf /etc/clamav/freshclam.conf
  download_sudo https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/clamav/virus-event.sh /etc/clamav/virus-event.sh
  sudo chmod 644 /etc/clamav/clamd.conf /etc/clamav/freshclam.conf
  sudo touch /var/log/clamav/clamd.log /var/log/clamav/freshclam.log
  sudo chmod 600 /var/log/clamav/clamd.log /var/log/clamav/freshclam.log
  sudo chown clamav:clamav /var/log/clamav/clamd.log /var/log/clamav/freshclam.log
  sudo chmod 555 /etc/clamav/virus-event.sh

  sudo systemctl enable --now clamav-daemon.socket
  sudo systemctl enable --now clamav-daemon
  print "=== Updating ClamAV db via freshclam... ==="
  sudo freshclam
  sudo systemctl enable --now clamav-freshclam
end

if not is_command crontab
  print "=== Installing cronie... ==="
  install_repo cronie
  sudo systemctl enable --now cronie
end

if not test (sudo crontab -l -u root | grep clamdscan)
  print "=== Scheduling ClamAV scan of downloads folder ... ==="
  echo "*/5 * * * * clamdscan --fdpass /home/niko/Downloads" > /tmp/crontab-append
  sudo crontab -l -u root | cat - /tmp/crontab-append | sudo crontab -u root -
end

if test -e ~/.config/zoomus.conf
  print "=== Configuring Zoom client... ==="
  replace ~/.config/zoomus.conf "autoPlayGif=false" "autoPlayGif=true"
  replace ~/.config/zoomus.conf "captureHDCamera=false" "captureHDCamera=true"
  replace ~/.config/zoomus.conf "playSoundForNewMessage=false" "playSoundForNewMessage=true"
  replace ~/.config/zoomus.conf "showSystemTitlebar=false" "showSystemTitlebar=true"
  replace ~/.config/zoomus.conf "timeFormat12HoursEnable=true" "timeFormat12HoursEnable=false"
  replace ~/.config/zoomus.conf "useSystemTheme=false" "useSystemTheme=true"
end

# file search tool: https://github.com/cboxdoerfer/fsearch
if not is_command fsearch
  print "=== Installing and configuring fsearch... ==="
  install fsearch-git
  download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/fsearch/fsearch.conf ~/.config/fsearch/fsearch.conf
end

# cool resources monitor: https://github.com/aristocratos/btop
if not is_command btop
  print "=== Installing btop... ==="
  install_repo btop
end
if not test -e ~/.config/btop/btop.conf
  print "=== Installing btop configuration... ==="
  download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/btop/btop.conf ~/.config/btop/btop.conf
end

# copy and set wallpapers
mkdir -p ~/.local/share/wallpapers/
if not test (count ~/.local/share/wallpapers/cachygalaxy*.jpg) = 2
  print "=== Downloading wallpapers to system... ==="
  download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/desktop/wallpapers/cachygalaxy99.jpg ~/.local/share/wallpapers/cachygalaxy99.jpg
  download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/desktop/wallpapers/cachygalaxy99-bernd.jpg ~/.local/share/wallpapers/cachygalaxy99-bernd.jpg
  print "=== Applying desktop wallpaper... ==="
  plasma-apply-wallpaperimage ~/.local/share/wallpapers/cachygalaxy99-bernd.jpg
end

# install KDE cursor themes:
#  - https://github.com/ful1e5/Bibata_Cursor
#  - https://github.com/ful1e5/banana-cursor
print "=== Installing KDE Bibata cursor (default cursor)... ==="
download_extract https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz ~/.icons
print "=== Installing KDE Banana cursor (fun cursor)... ==="
download_extract https://github.com/ful1e5/banana-cursor/releases/latest/download/banana-all.tar.xz ~/.icons

if test -d ~/.gnupg/
  if test -e ~/.gnupg/gpg.conf
    print "=== Configuring GPG agent... ==="
    echo "enable-ssh-support" >> ~/.gnupg/gpg-agent.conf
    echo "use-agent" >> ~/.gnupg/gpg.conf
    gpg-connect-agent reloadagent /bye
  end
  print "=== Making sure GPG file permissions are correct... ==="
  chown -R $(whoami) ~/.gnupg/
  find ~/.gnupg/ -type f -exec chmod 600 {} \; # Owner read/write (600) for files
  find ~/.gnupg/ -type d -exec chmod 700 {} \; # Owner read/write/execute (700) for directories
end

# enable IPv6 privacy extensions: https://wiki.archlinux.org/title/IPv6#Privacy_extensions
if test (grep -zoP "# Enable IPv6 Privacy Extensions\nnet.ipv6.conf.all.use_tempaddr = 2\nnet.ipv6.conf.default.use_tempaddr = 2" /etc/sysctl.d/40-ipv6.conf | wc -l) -ne 2
  print "=== Configuring IPv6 privacy extensions"
  echo "# Enable IPv6 Privacy Extensions
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2" | sudo tee -a /etc/sysctl.d/40-ipv6.conf > /dev/null
end

if not is_customized /etc/ssh/ssh_config
  print "=== Detected ssh_config in initial state, overwriting with custom config ==="
  sudo cp /etc/ssh/ssh_config /etc/ssh/ssh_config.backup
  download_sudo https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/ssh/ssh_config /etc/ssh/ssh_config
end

# unused packages
if is_command plasma-browser-integration-host
  print "=== Removing 'plasma-browser-integration-host'... ==="
  uninstall plasma-browser-integration
end

if not pacman -Q ttf-twemoji-color > /dev/null 2>&1
  print "=== Installing emoji font to fix rendering issues... ==="
  install ttf-twemoji-color
end

# default browser: https://librewolf.net
if not is_command librewolf
  print "=== Installing librewolf... ==="
  install librewolf-bin
end
if not test -e ~/.librewolf/librewolf.overrides.cfg
  print "=== Installing custom librewolf configuration... ==="
else
  print "=== Updating custom librewolf configuration... ==="
end
cp ~/.librewolf/librewolf.overrides.cfg ~/.librewolf/librewolf.overrides.cfg.backup
download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/browser/librewolf.overrides.cfg ~/.librewolf/librewolf.overrides.cfg

# backup browser: https://vivaldi.com
if not is_command vivaldi
  print "=== Installing Vivaldi... ==="
  install vivaldi
end

# default editor: https://vscodium.com
if not is_command codium
  print "=== Installing codium... ==="
  install vscodium-bin
end
print "=== Updating custom VSCodium configuration... ==="
cp ~/.config/VSCodium/User/settings.json ~/.config/VSCodium/User/settings.json.backup
download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/vscodium/settings.json ~/.config/VSCodium/User/settings.json
print "=== Installing codium extensions... ==="
# Save currently installed extensions with:
# codium --list-extensions > vscodium/extensions.txt
fetch https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/vscodium/extensions.txt | xargs -L 1 codium --install-extension

# Arch Linux update helper: https://github.com/CachyOS/cachy-update
if not is_command arch-update
  print "=== Installing and configuring arch-update (cachy-update)... ==="
  install_repo cachy-update
  download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/cachy-update/arch-update.conf ~/.config/arch-update/arch-update.conf
  if test -f ~/.config/autostart/arch-update-tray.desktop
    rm ~/.config/autostart/arch-update-tray.desktop
  end
  arch-update --tray --enable
  systemctl --user enable --now arch-update.timer
end

# audio effects: https://github.com/wwmm/easyeffects
if not test (flatpak list | grep com.github.wwmm.easyeffects)
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak install flathub com.github.wwmm.easyeffects

  download_extract https://download-directory.github.io/?url=https://github.com/cyb3rko/cachykde-handbook/tree/main/easyeffects/presets/input ~/.var/app/com.github.wwmm.easyeffects/data/easyeffects/input
end

# GitHub cli tool: https://cli.github.com/
if not is_command gh
  print "=== Installing and setting up GitHub CLI... ==="
  install_repo github-cli
  gh auth login
end

# fast & modern Python package manager: https://docs.astral.sh/uv
if not is_command uv
  print "=== Installing uv... ==="
  execute https://astral.sh/uv/install.sh
else
  print "=== Self-updating uv... ==="
  uv self update
  print "=== Updating uvx tools... ==="
  uv tool upgrade --all
end

# Nitrokey 3 software: https://www.nitrokey.com/products/nitrokeys
if not is_command nitropy
  print "=== Installing nitropy... ==="
  paru python-pynitrokey
  nitropy version
  wget https://raw.githubusercontent.com/Nitrokey/nitrokey-udev-rules/main/41-nitrokey.rules
  sudo mv 41-nitrokey.rules /etc/udev/rules.d/
  sudo chown root:root /etc/udev/rules.d/41-nitrokey.rules
  sudo chmod 644 /etc/udev/rules.d/41-nitrokey.rules
  sudo udevadm control --reload-rules && sudo udevadm trigger
end

# automatically purge old files from trash: https://github.com/bneijt/autotrash
if not is_command autotrash
  print "=== Installing and configuring autotrash... ==="
  uv tool install autotrash
  autotrash -d 40 --install
end

if not is_command pre-commit
  print "=== Installing pre-commit... ==="
  uv tool install pre-commit --with pre-commit-uv
  pre-commit --version
end

# node version manager: https://github.com/nvm-sh/nvm
if not is_function nvm
  print "=== Installing nvm and Node... ==="
  install nvm
  source ~/.config/fish/config.fish
  nvm use node
end

# node package manager: https://pnpm.io
if not is_command pnpm
  print "=== Installing pnpm... ==="
  execute https://get.pnpm.io/install.sh
else
  print "=== Self-updating pnpm... ==="
  pnpm self-update | grep -v "^Nothing to stop."
end

# Linux onedrive sync client: https://github.com/abraunegg/onedrive
if not is_command onedrive
  print "=== Installing onedrive client... ==="
  install onedrive-abraunegg
  sudo mkdir /var/log/onedrive
  sudo chown root:(whoami) /var/log/onedrive
  sudo chmod 0775 /var/log/onedrive
  mkdir -p ~/.config/onedrive
  download "https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/onedrive/config" ~/.config/onedrive/config
  download "https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/onedrive/sync_list" ~/.config/onedrive/sync_list
end

# well, it's Docker
if not is_command docker
  print "=== Installing rootless Docker... ==="
  download "https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/docker/daemon.json" ~/.config/docker/daemon.json
  execute https://get.docker.com/rootless
  set path_vars ~/.path_vars
  set docker_bin_path ~/bin
  if not grep -q $docker_bin_path $path_vars
    echo $docker_bin_path >> $path_vars
  end
  set env_path ~/.env
  set docker_host "DOCKER_HOST=unix:///run/user/1000/docker.sock"
  if not grep -q $docker_host $env_path
    echo $docker_host >> $env_path
  end
end

# required for AppImages
if not pacman -Q | grep -q fuse3
  print "=== Installing fuse3 to be able to use AppImages... ==="
  install_repo fuse3
end

# Bruno (HTTP client): https://usebruno.com
if not is_command bruno
  print "=== Installing Bruno... ==="
  install bruno-bin
end

# Gimp: https://www.gimp.org
if not is_command gimp
  print "=== Installing Gimp... ==="
  install_repo gimp
end

# JetBrains toolbox for JetBrains IDEs: https://www.jetbrains.com/toolbox-app/
# Installer: https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/jetbrains-toolbox.sh
# Installer based on: https://github.com/nagygergo/jetbrains-toolbox-install
if not test -d ~/.local/share/JetBrains/Toolbox/bin
  print "=== Installing JetBrains toolbox... ==="
  execute https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/jetbrains-toolbox.sh
end

# universal video downloader tool: https://github.com/yt-dlp/yt-dlp
if not is_command yt-dlp
  print "=== Installing yt-dlp... ==="
  download_sudo https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp /usr/local/bin/yt-dlp
  sudo chmod a+rx /usr/local/bin/yt-dlp
end

if sudo dmidecode -s system-manufacturer | grep -qi "Tuxedo"
  # On laptop

  # set cursor
  print "=== Setting cursor... ==="
  plasma-apply-cursortheme Bibata-Modern-Ice # alternative: Banana
  # TUXEDO specific tools and drivers
  set packages (pacman -Q | grep tuxedo | count)
  if test $packages -ne 3
    print "=== Tuxedo detected - Installing tools and drivers... ==="
    install tuxedo-drivers-dkms
    install tuxedo-control-center-bin
    install tuxedo-webfai-creator-bin
  end
  if not test -f ~/Dokumente/tuxedo/TCC_Profiles_Backup.json
    print "=== Tuxedo - Fetching control center profiles... ==="
    download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/tuxedo/TCC_Profiles_Backup.json ~/Dokumente/tuxedo/TCC_Profiles_Backup.json
  end
else
  # Not on laptop

  # set cursor
  print "=== Setting cursor... ==="
  plasma-apply-cursortheme Bibata-Modern-Ice # alternative: Banana
  # device manager for Logitech devices: https://github.com/pwr-Solaar/Solaar
  if not is_command solaar
    print "=== Installing solaar... ==="
    install_repo solaar
  end
  # configure autostart
  download_sudo https://raw.githubusercontent.com/pwr-Solaar/Solaar/refs/heads/master/share/autostart/solaar.desktop /etc/xdg/autostart/solaar.desktop
  # give permissions
  download_sudo https://raw.githubusercontent.com/pwr-Solaar/Solaar/master/rules.d-uinput/42-logitech-unify-permissions.rules /etc/udev/rules.d/42-logitech-unify-permissions.rules
  # update rules
  download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/solaar/config.yaml ~/.config/solaar/config.yaml
  download https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/solaar/rules.yaml ~/.config/solaar/rules.yaml
  sudo udevadm control --reload-rules
  # video editor: https://kdenlive.org
  if not is_command kdenlive
    print "=== Installing kdenlive... ==="
    install_repo kdenlive
  end
end

# color picker: https://apps.kde.org/kcolorchooser
if not is_command kcolorchooser
  print "=== Installing KColorChooser... ==="
  install_repo kcolorchooser
end

# well, it's Signal
if not is_command signal-desktop
  print "=== Installing Signal Desktop... ==="
  install_repo signal-desktop
end

# well, it's Element
if not is_command element-desktop
  print "=== Installing Element Desktop... ==="
  install_repo element-desktop
end

# disk usage analyzer tool
if not is_command ncdu
  print "=== Installing ncdu... ==="
  install_repo ncdu
end

# helper to install Proton versions
if not is_command protonplus
  print "=== Installing protonplus... ==="
  install_repo protonplus
end

# install KDE window open/close effects: https://github.com/Schneegans/Burn-My-Windows
print "=== Installing KDE window open/close effects... ==="
download_extract https://github.com/Schneegans/Burn-My-Windows/releases/latest/download/burn_my_windows_kwin6.tar.gz ~/.local/share/kwin/effects

# rerate CachyOS mirrors
if test -e ~/.cachymirrors
  set reference_point (date -d "-2 weeks" +%s)
  set checkpoint (cat ~/.cachymirrors)
  if test $reference_point -lt $checkpoint
    print "=== Setup finished :) ==="
    exit 0
  end
end
print "=== Rating CachyOS mirrors... ==="
sudo cachyos-rate-mirrors | grep -v "^Server = "
set current_stamp (date +%s)
echo $current_stamp > ~/.cachymirrors
print "=== Setup finished :) ==="
