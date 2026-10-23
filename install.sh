#!/bin/bash
# =======================================================
# SpeedyOs Universal Optimizer & Hardware Driver Engine v0.2
# =======================================================

echo "⚡ SpeedyOs Evrensel Kurulum Sistemi Başlatılıyor..."

# 1. DAĞITIM TESPİTİ VE DEPO GÜNCELLEMESİ
if [ -f /etc/debian_version ]; then
    DISTRO="Debian/Ubuntu"
    echo "📌 Algılanan Dağıtım: $DISTRO"
    sudo apt update -y
elif [ -f /etc/arch-release ]; then
    DISTRO="Arch"
    echo "📌 Algılanan Dağıtım: $DISTRO"
    sudo pacman -Syy --noconfirm
elif [ -f /etc/fedora-release ]; then
    DISTRO="Fedora"
    echo "📌 Algılanan Dağıtım: $DISTRO"
    sudo dnf check-update -y
fi

# EVRENSEL PAKET YÜKLEME FONKSİYONU
install_pkg() {
    if [ "$DISTRO" = "Debian/Ubuntu" ]; then
        sudo apt install -y "$@"
    elif [ "$DISTRO" = "Arch" ]; then
        sudo pacman -S --noconfirm "$@"
    elif [ "$DISTRO" = "Fedora" ]; then
        sudo dnf install -y "$@"
    fi
}

# 2. ŞARJ / PİL OTOMATİK GÜÇ DÜZENLEYİCİSİ (auto-cpufreq)
echo "🔋 Otomatik Güç Algılama Sistemi Yükleniyor..."
install_pkg auto-cpufreq 2>/dev/null || true
sudo auto-cpufreq --install 2>/dev/null || true

# 3. EKRAN KARTI (GPU) SÜRÜCÜ TESPİTİ VE KURULUMU
echo "🎮 Ekran Kartı Sürücüleri Denetleniyor..."
GPU_INFO=$(lspci | grep -iE 'vga|3d')

if echo "$GPU_INFO" | grep -i "NVIDIA" > /dev/null; then
    echo "🚀 NVIDIA (RTX/GTX) Ekran Kartı Algılandı!"
    if [ "$DISTRO" = "Debian/Ubuntu" ]; then
        install_pkg nvidia-driver nvidia-smi
    elif [ "$DISTRO" = "Arch" ]; then
        install_pkg nvidia nvidia-utils
    elif [ "$DISTRO" = "Fedora" ]; then
        install_pkg akmod-nvidia
    fi
elif echo "$GPU_INFO" | grep -i "AMD" > /dev/null; then
    echo "🔴 AMD GPU Algılandı, Mesa Sürücüleri Güncelleniyor..."
    if [ "$DISTRO" = "Debian/Ubuntu" ]; then
        install_pkg mesa-vulkan-drivers
    elif [ "$DISTRO" = "Arch" ]; then
        install_pkg vulkan-radeon
    elif [ "$DISTRO" = "Fedora" ]; then
        install_pkg mesa-vulkan-drivers
    fi
fi

# 4. BULANIKLIK EFEKTİ (PICOM BLUR = 10)
echo "✨ Bulanıklık Efekti (Blur = 10) Yapılandırılıyor..."
install_pkg picom

mkdir -p ~/.config/picom/
cat << 'EOF' > ~/.config/picom/picom.conf
# SpeedyOs Visual Engine
backend = "glx";
blur-background = true;
blur-method = "dual_kawase";
blur-strength = 10;
corner-radius = 8;
EOF

# 5. RAM-DISK (TMPFS) VE I/O ENTEGRASYONU
cat << 'EOF' | sudo tee /etc/sysctl.d/99-speedyos.conf
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.dirty_writeback_centisecs = 1500
vm.swappiness = 10
EOF

sudo sysctl --system

echo "🎉 SpeedyOs Başarıyla Kuruldu! Sisteminiz Ateş Ediyor."
