#!/bin/bash
# =======================================================
# SpeedyOs Universal Optimizer & Hardware Driver Engine
# =======================================================

echo "⚡ SpeedyOs Evrensel Kurulum Sistemi Başlatılıyor..."

# 1. DAĞITIM TESPİTİ
if [ -f /etc/debian_version ]; then
    DISTRO="Debian/Ubuntu"
    PKG_INSTALL="sudo apt update && sudo apt install -y"
elif [ -f /etc/arch-release ]; then
    DISTRO="Arch"
    PKG_INSTALL="sudo pacman -Syy --noconfirm"
elif [ -f /etc/fedora-release ]; then
    DISTRO="Fedora"
    PKG_INSTALL="sudo dnf install -y"
fi

echo "📌 Algılanan Dağıtım: $DISTRO"

# 2. ŞARJ / PİL OTOMATİK GÜÇ DÜZENLEYİCİSİ (auto-cpufreq)
echo "🔋 Otomatik Güç Algılama Sistemi Yükleniyor..."
$PKG_INSTALL auto-cpufreq 2>/dev/null || true
sudo auto-cpufreq --install 2>/dev/null || true

# 3. EKRAN KARTI (GPU) SÜRÜCÜ TESPİTİ VE KURULUMU
echo "🎮 Ekran Kartı Sürücüleri Denetleniyor..."
GPU_INFO=$(lspci | grep -iE 'vga|3d')

if echo "$GPU_INFO" | grep -i "NVIDIA" > /dev/null; then
    echo "🚀 NVIDIA (RTX/GTX) Ekran Kartı Algılandı!"
    if [ "$DISTRO" = "Debian/Ubuntu" ]; then
        $PKG_INSTALL nvidia-driver nvidia-smi
    elif [ "$DISTRO" = "Arch" ]; then
        $PKG_INSTALL nvidia nvidia-utils
    elif [ "$DISTRO" = "Fedora" ]; then
        $PKG_INSTALL akmod-nvidia
    fi
elif echo "$GPU_INFO" | grep -i "AMD" > /dev/null; then
    echo "🔴 AMD GPU Algılandı, Mesa Sürücüleri Güncelleniyor..."
    $PKG_INSTALL mesa-vulkan-drivers 2>/dev/null || $PKG_INSTALL vulkan-radeon
fi

# 4. BULANIKLIK EFEKTİ (PICOM BLUR = 10)
echo "✨ Bulanıklık Efekti (Blur = 10) Yapılandırılıyor..."
$PKG_INSTALL picom

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
