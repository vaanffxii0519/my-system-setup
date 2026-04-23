#!/bin/bash
# บังคับให้สคริปต์หยุดทำงานทันทีถ้ามีบรรทัดไหนเกิด Error (Safety net)
set -e

echo "🚀 Starting System Provisioning (The Power User Golden Flow)..."

# 1. ติดตั้งเครื่องมือพื้นฐาน, ฟอนต์ JetBrains Mono และสภาพแวดล้อม Python
echo "📦 1/7 Updating system and installing base packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release fonts-jetbrains-mono python3 python3-pip python3-venv

# 2. ติดตั้ง Docker Engine
if ! command -v docker &> /dev/null; then
    echo "🐳 2/7 Installing Docker Engine..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # เพิ่ม User ปัจจุบันเข้า Group Docker เพื่อให้ใช้คำสั่ง docker ได้โดยไม่ต้องพิมพ์ sudo ในอนาคต
    sudo usermod -aG docker $USER
else
    echo "✅ 2/7 Docker is already installed."
fi

# 3. ติดตั้งและรัน Portainer (ใช้ sudo นำหน้าเพราะเพิ่งแอด Group เมื่อกี้ Shell ยังไม่รับทราบ)
echo "🚢 3/7 Setting up Portainer..."
# สร้าง Volume เก็บข้อมูล (ถ้ามีอยู่แล้วคำสั่ง || true จะช่วยไม่ให้สคริปต์พัง)
sudo docker volume create portainer_data || true

# เช็กว่ามี Portainer รันอยู่แล้วหรือไม่ ถ้ายังไม่มีให้สร้างขึ้นมาใหม่
if ! sudo docker ps -a --format '{{.Names}}' | grep -Eq "^portainer\$"; then
    sudo docker run -d \
      -p 8000:8000 \
      -p 9443:9443 \
      --name portainer \
      --restart always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-ce:latest
    echo "✅ Portainer started successfully."
else
    echo "⏩ Portainer is already running."
fi

# 4. ติดตั้ง VS Code
if ! command -v code &> /dev/null; then
    echo "💻 4/7 Installing VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg
    sudo apt update
    sudo apt install -y code
else
    echo "✅ 4/7 VS Code is already installed."
fi

# 5. ติดตั้ง TLP (ตรวจจับ ThinkPad หรือ Lenovo อัตโนมัติ)
if [[ $(cat /sys/class/dmi/id/chassis_vendor 2>/dev/null) == *"Lenovo"* ]] || [[ $(hostname) == *"ThinkPad"* ]]; then
    echo "🔋 5/7 Lenovo/ThinkPad detected. Installing TLP..."
    sudo apt install -y tlp tlp-rdw
    sudo tlp start
else
    echo "⏩ 5/7 Skipping TLP (Not a Lenovo/ThinkPad)."
fi

# 6. ติดตั้ง NVM และ Node.js LTS
if [ ! -d "$HOME/.nvm" ]; then
    echo "🟢 6/7 Installing NVM and Node.js LTS..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    
    # Reload Shell Environment สดๆ เพื่อให้สคริปต์รู้จักคำสั่ง nvm ทันที
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # ติดตั้ง Node ล่าสุด (LTS) และตั้งเป็น Default
    nvm install --lts
    nvm alias default 'lts/*'
else
    echo "✅ 6/7 NVM is already installed."
fi

# 7. ติดตั้ง Chezmoi และบังคับดึง Config เข้าระบบ
if ! command -v chezmoi &> /dev/null; then
    echo "🏠 7/7 Installing Chezmoi..."
    sudo curl -sfL https://git.io/chezmoi | sudo sh -s -- -b /usr/local/bin
else
    echo "✅ 7/7 Chezmoi is already installed."
fi

echo "🪄 Applying configurations via Chezmoi..."
# ดึงโฟลเดอร์ปัจจุบัน (ที่โคลนมาจาก Git) เข้าไปจัดการเป็น Source ของ Chezmoi และ Apply ทันที
chezmoi init --apply --source "$(pwd)"

echo "==========================================================="
echo "🎉 BOOTSTRAP COMPLETE! 🎉"
echo "⚠️ IMPORTANT ACTIONS REQUIRED:"
echo "1. 🔄 PLEASE RESTART YOUR COMPUTER NOW to apply Docker groups."
echo "2. 🌐 Open https://localhost:9443 in your browser to set up Portainer."
echo "   (You MUST do this within 12 minutes of the container starting!)"
echo "==========================================================="