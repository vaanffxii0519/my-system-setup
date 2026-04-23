#!/bin/bash
echo "🧩 Installing VS Code Extensions..."

extensions=(
    "ms-python.black-formatter"
    "ms-vscode.cpptools"
    "ms-vscode.cmake-tools"
    "ms-azuretools.vscode-docker"
    "usernamehw.errorlens"
    "espressif.esp-idf-extension"
    "github.vscode-github-actions"
    "eamodio.gitlens"
    "ms-python.isort"
    "PKief.material-icon-theme"
    "esbenp.prettier-vscode"
    "ms-python.vscode-pylance"
    "ms-python.python"
    "rangav.vscode-thunder-client"
    "redhat.vscode-yaml"
)

for ext in "${extensions[@]}"; do
    code --install-extension "$ext" --force
done