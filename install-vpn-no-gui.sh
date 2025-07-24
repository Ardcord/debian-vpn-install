#!/bin/bash

set -e

# Couleurs
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color (reset)

update_system() {
	echo -e "${GREEN}[+] Nettoyage des caches APT et journaux...${NC}"
	sudo apt clean
	sudo journalctl --vacuum-size=20M || true

	echo -e "${GREEN}[+] Mise à jour du système...${NC}"
	sudo apt update && sudo apt upgrade -y
}

install_essential_packages() {
	echo -e "${GREEN}[+] Installation des paquets essentiels...${NC}"
	sudo apt install -y -qq git curl wget zsh openvpn iproute2 net-tools neofetch
}

setup_unattended_upgrades() {
	echo -e "${GREEN}[+] Activation des mises à jour automatiques...${NC}"
	sudo apt install -y unattended-upgrades
	sudo dpkg-reconfigure unattended-upgrades > /dev/null 2>&1

	UPGRADE_FILE="/etc/apt/apt.conf.d/50unattended-upgrades"

	sudo sed -i 's|^//.*\(${distro_id}:[^"]*${distro_codename}-updates";\)|\1|' "$UPGRADE_FILE"
	sudo sed -i 's|^//\s*\(Unattended-Upgrade::Automatic-Reboot "true";\)|\1|' "$UPGRADE_FILE"
	grep -q 'Unattended-Upgrade::Automatic-Reboot "true";' "$UPGRADE_FILE" || \
		sudo bash -c 'echo "Unattended-Upgrade::Automatic-Reboot \"true\";" >> '"$UPGRADE_FILE"
	sudo sed -i 's|^//\s*\(Unattended-Upgrade::Automatic-Reboot-Time "03:00";\)|\1|' "$UPGRADE_FILE"
	grep -q 'Unattended-Upgrade::Automatic-Reboot-Time "03:00";' "$UPGRADE_FILE" || \
		sudo bash -c 'echo "Unattended-Upgrade::Automatic-Reboot-Time \"03:00\";" >> '"$UPGRADE_FILE"
	sudo systemctl restart unattended-upgrades
	echo -e "${GREEN}[+] Mises à jour automatiques configurées !"
}


setup_ssh() {
	echo -e "${GREEN}[+] Installation de openssh...${NC}"

	if ! dpkg -l | grep -q openssh-server; then
		sudo apt install -y -qq openssh-server
	fi

	sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
	sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
	sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
	sudo sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
	if systemctl list-units --type=service --all | grep -q '^ssh\.service'; then
		sudo systemctl restart ssh
	elif systemctl list-units --type=service --all | grep -q '^sshd\.service'; then
		sudo systemctl restart sshd
	else
		echo -e "${RED}[!] Aucun service SSH actif détecté${NC}"
	fi
}

setup_grub() {
	echo -e "${GREEN}[+] Configuration de GRUB...${NC}"

	sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
	sudo update-grub
}

setup_ohmyzsh() {
	echo -e "${GREEN}[+] Installation de Oh My Zsh...${NC}"
	
	[ -d /opt/oh-my-zsh ] || sudo git clone https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh  > /dev/null 2>&1
	[ -d /opt/oh-my-zsh/custom/plugins/zsh-autosuggestions ] || sudo git clone https://github.com/zsh-users/zsh-autosuggestions /opt/oh-my-zsh/custom/plugins/zsh-autosuggestions  > /dev/null 2>&1
	[ -d /opt/oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] || sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting /opt/oh-my-zsh/custom/plugins/zsh-syntax-highlighting  > /dev/null 2>&1

	sudo chmod -R a+rX /opt/oh-my-zsh

	echo -e "${GREEN}[+] Création du .zshrc et .zsh_history partagés dans /opt...${NC}"

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

get_ip() {
    # Affiche la première IP non-loopback, version simple
    ip -4 addr | awk '/inet / && $2 !~ /^127/ {gsub(/\/.*/, "", $2); print $2; exit}'
}

case "$TERM" in
    linux)
        PROMPT='%F{46}┌──[%F{201}%m%F{46} | %F{45}$(get_ip)%F{46} | %F{51}%n%F{46}]%f'$'\n''%F{46}└──╼[%F{44}%*%F{46}] %F{44}%~ $%f '
        ;;
    *)
        PROMPT="%F{46}┌──[HQ🚀🌐%F{201}$(ip -4 addr | grep -v '127.0.0.1' | grep -v 'secondary' | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | sed -z 's/\n/|/g;s/|\$/\n/' | rev | cut -c 2- | rev)🔥%n%F{46}]"$'\n'"└──╼[👾]%F{44}%~ $%f "
        ;;
esac

neofetch
EOF

	sudo touch /opt/zsh_history
	sudo chmod 644 /opt/.zshrc
	sudo chmod 666 /opt/zsh_history

	echo -e "${GREEN}[+] Liens symboliques pour root et les utilisateurs...${NC}"

	for user in root $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
		echo -e "${GREEN}[+] Liens pour $user"
		USER_HOME=$(eval echo -e "~$user")

		ln -sf /opt/.zshrc "$USER_HOME/.zshrc"
		ln -sf /opt/zsh_history "$USER_HOME/.zsh_history"

		chown -h "$user:$user" "$USER_HOME/.zshrc" "$USER_HOME/.zsh_history"
		chsh -s "$(which zsh)" "$user"
	done
}

main() {
	update_system
	install_essential_packages
	setup_unattended_upgrades
	setup_ssh
	setup_grub
	setup_ohmyzsh
	sudo apt autoremove -y -qq > /dev/null 2>&1
	echo -e "${GREEN}[+] Nettoyage terminé !${NC}"

	echo -e "${GREEN}[+] Installation terminée !"
	echo -e "${GREEN}Source ${NC}/opt/.zshrc ${GREEN}pour appliquer les changements.${NC}"
}