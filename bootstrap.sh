#!/bin/bash
set -e

echo "🚀 Starting System Provisioning..."

# 1. ติดตั้งเครื่องมือพื้นฐาน และ Python
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release fonts-jetbrains-mono python3 python3-pip python3-venv

# 2. ติดตั้ง Docker Engine & Compose
if ! command -v docker &> /dev/null; then
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
fi

# 3. รัน Portainer
sudo docker volume create portainer_data || true
sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest || true

# 4. ติดตั้ง VS Code
if ! command -v code &> /dev/null; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg
    sudo apt update
    sudo apt install -y code
fi

# 5. ติดตั้ง TLP (เช็กว่าเป็น ThinkPad/Lenovo หรือไม่)
if [[ $(cat /sys/class/dmi/id/chassis_vendor 2>/dev/null) == *"Lenovo"* ]] || [[ $(hostname) == *"ThinkPad"* ]]; then
    sudo apt install -y tlp tlp-rdw
    sudo tlp start
fi

# 6. ติดตั้ง NVM และ Node.js LTS
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm alias default 'lts/*'
fi

# 7. ติดตั้ง Chezmoi และสั่งให้มันทำงานทันที
if ! command -v chezmoi &> /dev/null; then
    sudo curl -sfL https://git.io/chezmoi | sudo sh -s -- -b /usr/local/bin
fi

echo "🏠 Applying configurations via Chezmoi..."
# สั่ง Chezmoi ให้ดึง Config จากโฟลเดอร์นี้ไปจัดแจงในระบบ
chezmoi init --apply --source "$(pwd)"

echo "🎉 All Done! Please RESTART your computer."