# VPN Light Installer

Script shell automatisé pour déployer rapidement un serveur VPN (OpenVPN), Zsh, et Oh My Zsh avec plugins, sur une machine Debian/Ubuntu avec peu d’espace disque.

---

## ✨ Fonctionnalités

- Nettoyage et mise à jour du système
- Installation minimale des paquets nécessaires
- Installation de Zsh + Oh My Zsh (version partagée dans `/opt`)
- Activation des plugins : `sudo`, `zsh-autosuggestions`, `zsh-syntax-highlighting`
- Prompt personnalisé avec IP dynamique
- Support multi-utilisateur (config `.zshrc` et `.zsh_history` centralisée via liens symboliques)
- Téléchargement du script d'installation OpenVPN

---

## 🧾 Prérequis

- Système basé sur Debian ou Ubuntu avec `apt`
- Accès root ou `sudo`
- `wget`, `curl` ou `git`
    

- Connexion Internet

---

## 🚀 Installation

wget methode
```sh
wget https://raw.githubusercontent.com/Ardcord/](https://raw.githubusercontent.com/Ardcord/debian-vpn-install/main/install-vpn.sh
chmod +x install-vpn.sh
./install-vpn.sh
```

Git methode
```bash
git clone https://github.com/Ardcord/vpn-light-installer.git
cd vpn-light-installer
chmod +x install-vpn.sh
./install-vpn.sh
```

  Note importante : La partie VPN de ce script s'appuie sur le script maintenu par Nyr/openvpn-install,
    https://github.com/Nyr/openvpn-install
    
Celui-ci est téléchargé automatiquement via :
```sh
wget https://git.io/vpn -O openvpn-install.sh
```

Ce script externe propose une configuration complète d'un serveur OpenVPN en quelques étapes interactives.
