#!/bin/bash

set -e

echo "[+] Nettoyage des caches APT et journaux..."
sudo apt clean
sudo journalctl --vacuum-size=20M || true

echo "[+] Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

echo "[+] Installation des paquets essentiels..."
sudo apt install -y git curl wget zsh openvpn iproute2 net-tools # neofetch

# echo "[+] Configuration SSH..."
# sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
# sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
# if systemctl list-units --type=service --all | grep -q '^ssh\.service'; then
#     sudo systemctl restart ssh
# elif systemctl list-units --type=service --all | grep -q '^sshd\.service'; then
#     sudo systemctl restart sshd
# else
#     echo "[!] Aucun service SSH actif détecté"
# fi

echo "[+] Installation partagée de Oh My Zsh dans /opt/oh-my-zsh..."
sudo git clone https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh
sudo git clone https://github.com/zsh-users/zsh-autosuggestions /opt/oh-my-zsh/custom/plugins/zsh-autosuggestions
sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting /opt/oh-my-zsh/custom/plugins/zsh-syntax-highlighting
sudo chmod -R a+rX /opt/oh-my-zsh

echo "[+] Création du .zshrc et .zsh_history partagés dans /opt..."

sudo tee /opt/.zshrc > /dev/null <<'EOF'
export ZSH="/opt/oh-my-zsh"
ZSH_THEME="robbyrussell"

HISTSIZE=100000000
SAVEHIST=100000000
HISTFILE=~/.zsh_history
setopt hist_ignore_dups
setopt append_history
setopt share_history

plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

alias ll='ls -lah'
alias la='ls -A'
alias c='clear'
alias grep='grep --color=auto'

if [[ $(tty) == */dev/tty* ]]; then
    PROMPT="%F{46}[HQ:%F{201}$(ip -4 addr | grep -v '127.0.0.1' | grep -v 'secondary' | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | sed -z 's/\n/|/g;s/|\$/\n/' | rev | cut -c 2- | rev) | %n%F{46}]"$'\n'"[>]%F{44}%~ $%f "
else
    PROMPT="%F{46}┌──[HQ🚀🌐%F{201}$(ip -4 addr | grep -v '127.0.0.1' | grep -v 'secondary' | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | sed -z 's/\n/|/g;s/|\$/\n/' | rev | cut -c 2- | rev)🔥%n%F{46}]"$'\n'"└──╼[👾]%F{44}%~ $%f "
fi

neofetch
EOF

sudo touch /opt/zsh_history
sudo chmod 644 /opt/.zshrc
sudo chmod 666 /opt/zsh_history

echo "[+] Liens symboliques pour root et les utilisateurs..."

for user in root $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
    echo "[+] Liens pour $user"
    USER_HOME=$(eval echo "~$user")

    ln -sf /opt/.zshrc "$USER_HOME/.zshrc"
    ln -sf /opt/zsh_history "$USER_HOME/.zsh_history"

    chown -h "$user:$user" "$USER_HOME/.zshrc" "$USER_HOME/.zsh_history"
    chsh -s "$(which zsh)" "$user"
done
