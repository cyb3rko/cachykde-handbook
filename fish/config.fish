# custom

function setabbreviations
  abbr ls "lla -l --no-dotfiles"
  abbr ll "lla -l"
  abbr lsd "lla -t -d"
  abbr update "yay"
  abbr install "yay"
  abbr remove "yay -R"
  abbr autoremove "sudo pacman -Rsn (pacman -Qtdq)"
  abbr clean "yay -Scc"

  abbr wsensor "watch -d -n 1 sensors"
  abbr dns-restart "sudo systemctl restart systemd-resolved"
  abbr git-repo "xdg-open $(git remote get-url origin 2>/dev/null) >/dev/null 2>&1"

  abbr jump "ssh root@jump.langen.cyb3rko"
  abbr oci-main "ssh niko@oci-main.cloud.cyb3rko"
  abbr oci-router "ssh root@oci-router.cloud.cyb3rko"
end

function envsource
  set -f log false
  if $log
    echo "Setting Environment variable from:  ~/.env"
  end
  set -f envfile "$argv"
  if not test -f "$envfile"
    echo "Unable to load $envfile"
    return 1
  end
  while read line
    if not string match -qr '^#|^$' "$line"
      set item (string split -m 1 '=' $line)
      set -gx $item[1] $item[2]
      if test -n "\$$item[2]"
        set -gx PATH $item[2] $PATH
      end
      if $log
        echo "Exported key: '$item[1] = $item[2]'"
      end
    end
  end < "$envfile"
end

function pathsource
  set -f log false
  if $log
    echo "Setting PATH variable from:  ~/.path_vars"
  end
  set -f pathfile "$argv"
  if not test -f "$pathfile"
    echo "Unable to load $pathfile"
    return 1
  end
  while read line
    if not string match -qr '^#|^$' "$line"
      set -gx PATH $PATH $line
      if $log
        echo "Added to PATH: '$line'"
      end
    end
  end < "$pathfile"
end

function nvm
    bash -c "source ~/.nvm/nvm.sh; nvm $argv"
end

source /usr/share/cachyos-fish-config/cachyos-config.fish
setabbreviations
envsource ~/.env
pathsource ~/.path_vars

set -U fish_user_paths /home/niko/.nvm/versions/node/*/bin $fish_user_paths

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
