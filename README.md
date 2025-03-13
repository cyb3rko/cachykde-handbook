# CachyOS KDE Handbook

System info: (CachyOS + KDE Plasma Wayland + fish shell)

---

- [Resource Management](#resource-management)
  - [Large file and folder monitor](#large-file-and-folder-monitor)
  - [Find large files](#find-large-files)
  - [Clean package manager caches](#clean-package-manager-caches)
  - [Rerate package mirrors](#rerate-package-mirros)
  - [AutoTrash](#autotrash)
  - [journalctl](#journalctl)
- [Services](#services)
  - [SSH Session Keep-Alive](#ssh-session-keep-alive)
  - [Java](#java)
- [Applications](#applications)
  - [AppImages](#appimages)
  - [Cachy Browser](#cachy-browser)
  - [OneDrive](#onedrive)
  - [Jetbrains Toolbox](#jetbrains-toolbox)
  - [nvm](#nvm)
  - [Steam](#steam)
  - [yt-dlp](#yt-dlp)
- [TLS](#tls)
  - [Import CA](#import-ca)

## Resource Management

### Large file and folder monitor

Use the CLI tool ncdu for a simple overview of the largest files and folders.

```shell
sudo pacman -S ncdu
ncdu /
```

### Find large files

Find files in current directory with a specified minimum size (in this example 100 MB)

```shell
find . -type f -size +100M
```

### Clean package manager caches

call this to start interactive package manager cache clearing

```shell
yay -Sc
```

### Rerate package mirros

```bash
sudo cachyos-rate-mirrors
```

### Autotrash

To automatically clear older files in the trash, run the following (example: files older than 40 days):

```shell
uv tool install autotrash
autotrash -d 40 --install
```

### journalctl

See space used by system logs:

```shell
journalctl --disk-usage
```

Set maximum log retention time in `/etc/systemd/journald.conf`:

```shell
MaxRetentionSec=1month
```

## Services

### SSH Session Keep-Alive

Edit `/etc/ssh/ssh_config` and append:

```shell
ServerAliveInterval 60
```

### Java

To install the correct version do the following and install the requested version:

```bash
sudo pacman -Ss java | grep jdk
```

To switch between installed java versions use:

```bash
archlinux-java
```

Set the `JAVA_HOME` env variable with the following config in `~/.env`:

```bash
JAVA_HOME=/usr/lib/jvm/default
```

## Applications

### AppImages

To use AppImage files, call the following:

```bash
sudo pacman -S fuse
```

### Cachy Browser

To apply policies to Cachy Browser via the [browser/policies2.json](browser/policies2.json), store it at `/usr/lib/cachy-browser/distribution` and manually add the policies to `/usr/lib/cachy-browser/distribution/policies.json`.  
Restart the browser and find applied policies at `about:policies`.

Custom configs not available with the centralized policy configuration:

- `full-screen-api.warning.timeout`: 0 (disables the fullscreen popup)
- `privacy.clearOnShutdown.cache`: false
- `privacy.clearOnShutdown.downloads`: false
- `privacy.clearOnShutdown.history`: false
- `privacy.clearOnShutdown_v2.browsingHistoryAndDownloads`: false
- `privacy.clearOnShutdown_v2.cache`: false
- `privacy.clearOnShutdown_v2.cookiesAndStorage`: false
- `privacy.clearOnShutdown_v2.historyFormDataAndDownloads`: false
- `privacy.resistFingerprinting`: false (loosen fingerprinting resistance)
- `reader.parse-on-load.enabled`: false (disables the simplified reader mode)
- `webgl.disabled`: false (allows WebGL)

### OneDrive

Install [abraunegg/onedrive](https://github.com/abraunegg/onedrive):

```shell
yay onedrive-abraunegg
```

- **d-compiler**: ldc
- **d-runtime**: liblphobos

To allow logging to `/var/log/onedrive`, do the following:

```shell
sudo mkdir /var/log/onedrive
sudo chown root:niko /var/log/onedrive
sudo chmod 0775 /var/log/onedrive
```

Initialize onedrive:  
```shell
onedrive
```

After initializing onedrive and BEFORE running the first sync, copy [config](onedrive/config) and [sync_list](onedrive/sync_list) to `~/.config/onedrive/`. Check the config with `onedrive --display-config`.

First sync:  
`onedrive --resync --sync`

### Jetbrains Toolbox

First allow AppImages (see [AppImages](#appimages)).

Then run [`jetbrains-toolbox.sh`](jetbrains-toolbox.sh).

### nvm

Install nvm like explained in their [README](https://github.com/nvm-sh/nvm?tab=readme-ov-file#install--update-script).  
Then add the following to `config.fish`:

```fish
function nvm
    bash -c "source ~/.nvm/nvm.sh; nvm $argv"
end

set -U fish_user_paths /home/niko/.nvm/versions/node/*/bin $fish_user_paths
```

### Steam

```bash
sudo pacman -S steam
```

- activate hardware acceleration in the Steam settings
- enable game emulation via Proton in the Steam settings

### yt-dlp

```shell
sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp
```

## TLS

### Import CA

1. Run `sudo trust anchor ca-file.pem`
2. Check import with `ls /etc/ca-certificates/trust-source`
3. (Test TLS connection with `openssl s_client -connect <host>:443`)
