#!/bin/bash
# =======================================================
# SpeedyOS - Evrensel Linux Arayüzü (ELOY Çekirdeği)
# =======================================================

echo "⚡ SpeedyOS - Evrensel Linux Arayüzü Başlatılıyor..."

# 1. DONANIM SEGMENTİ VE FORM FAKTÖRÜ SİHİRBAZI
echo -e "\n🖥️  Bilgisayarınızın Donanım Segmentini Seçin:"
echo "1) Eski / Düşük Donanımlı Bilgisayar (RAM < 4GB / HDD)"
echo "2) Orta Segment Bilgisayar"
echo "3) Oyuncu / Yüksek Performanslı PC (Örn: Excalibur G870)"
read -p "Seçiminiz (1/2/3): " SEGMENT_CHOICE

echo -e "\n💻 Bilgisayarınızın Form Faktörünü (Türünü) Seçin:"
echo "1) Masaüstü PC"
echo "2) Laptop / Dizüstü"
echo "3) Dokunmatik Ekranlı (2'si 1 arada / Tablet PC)"
read -p "Seçiminiz (1/2/3): " TYPE_CHOICE

case $SEGMENT_CHOICE in
    1) BLUR_STRENGTH=3; ZRAM_SIZE="2G"; ANIM_SPEED="0.25" ;;
    2) BLUR_STRENGTH=6; ZRAM_SIZE="4G"; ANIM_SPEED="0.35" ;;
    3) BLUR_STRENGTH=10; ZRAM_SIZE="6G"; ANIM_SPEED="0.35" ;;
    *) BLUR_STRENGTH=6; ZRAM_SIZE="4G"; ANIM_SPEED="0.35" ;;
esac

# 2. DAĞITIM TESPİTİ VE DEPO GÜNCELLEMESİ
if [ -f /etc/debian_version ]; then
    DISTRO="Debian/Ubuntu"
    sudo apt-get update
elif [ -f /etc/arch-release ]; then
    DISTRO="Arch"
    sudo pacman -Syy --noconfirm
elif [ -f /etc/fedora-release ]; then
    DISTRO="Fedora"
    sudo dnf check-update
fi
echo "📌 Algılanan Taban: $DISTRO"

install_pkg() {
    if [ "$DISTRO" = "Debian/Ubuntu" ]; then
        sudo apt-get install -y "$@" 2>/dev/null || true
    elif [ "$DISTRO" = "Arch" ]; then
        sudo pacman -S --noconfirm --needed "$@" 2>/dev/null || true
    elif [ "$DISTRO" = "Fedora" ]; then
        sudo dnf install -y "$@" 2>/dev/null || true
    fi
}

# 3. GÜÇ YÖNETİMİ VE EKRAN KARTI SÜRÜCÜLERİ
echo "🔋 Otomatik Güç ve GPU Sürücüleri Yapılandırılıyor..."
install_pkg auto-cpufreq
sudo auto-cpufreq --install 2>/dev/null || true

GPU_INFO=$(lspci 2>/dev/null | grep -iE 'vga|3d')
if echo "$GPU_INFO" | grep -iq "NVIDIA"; then
    echo "🚀 NVIDIA Ekran Kartı Algılandı!"
    [ "$DISTRO" = "Debian/Ubuntu" ] && install_pkg nvidia-driver nvidia-smi
    [ "$DISTRO" = "Arch" ] && install_pkg nvidia nvidia-utils
    [ "$DISTRO" = "Fedora" ] && install_pkg akmod-nvidia
elif echo "$GPU_INFO" | grep -iq "AMD"; then
    echo "🔴 AMD GPU Algılandı!"
    [ "$DISTRO" = "Debian/Ubuntu" ] && install_pkg mesa-vulkan-drivers
    [ "$DISTRO" = "Arch" ] && install_pkg vulkan-radeon
    [ "$DISTRO" = "Fedora" ] && install_pkg mesa-vulkan-drivers
fi

# 4. SPEEDYOS ARAYÜZ TEMASI, YÜZEN GÖREV ÇUBUĞU VE HIZLI ANİMASYONLAR
echo "🎨 Şık Arayüz Teması, Yüzen Görev Çubuğu ve Hızlı Animasyonlar Kuruluyor..."
install_pkg picom papirus-icon-theme arc-gtk-theme xdotool xorg-xprop

mkdir -p ~/.config/picom/
cat << EOF > ~/.config/picom/picom.conf
# SpeedyOS Evrensel Linux Arayüzü - Görsel Motor
backend = "glx";
vsync = true;

# Hızlı Pencere Animasyonları
fading = true;
fade-in-step = 0.08;
fade-out-step = 0.08;
fade-delta = 3;

# Cam Bulanıklığı ve Yüzen Pencere Köşeleri
blur-background = true;
blur-method = "dual_kawase";
blur-strength = ${BLUR_STRENGTH};
corner-radius = 12;
rounded-corners-exclude = [
  "window_type = 'desktop'"
];
EOF

if pgrep -x "plasmashell" > /dev/null; then
    echo "💠 KDE Plasma Algılandı: Yüzen Panel ve Hızlı Animasyonlar Uygulanıyor..."
    KWRITE=$(command -v kwriteconfig6 || command -v kwriteconfig5)
    if [ -n "$KWRITE" ]; then
        $KWRITE --file kdeglobals --group KDE --key AnimationDurationFactor "$ANIM_SPEED"
        $KWRITE --file kdeglobals --group Icons --key Theme "Papirus-Dark"
        sed -i 's/floating=0/floating=1/g' ~/.config/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null || true
    fi
else
    echo "🪟 Dock Motoru (Plank) Yüzen Görev Çubuğu Olarak Kuruluyor..."
    install_pkg plank
    mkdir -p ~/.config/autostart
    cat << 'EOF' > ~/.config/autostart/speedyos-dock.desktop
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=SpeedyOS Yüzen Görev Çubuğu
EOF
    gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null || true
    nohup plank >/dev/null 2>&1 &
fi

# 5. RAM, AĞ (TCP BBR), zRAM, KALICI HDD VE DISK ÖNBELLEK MODÜLÜ
echo "⚡ Çekirdek, zRAM, Kalıcı HDD ve Ağ Hızlandırma Katmanı Uygulanıyor..."
cat << 'EOF' | sudo tee /etc/sysctl.d/99-speedyos.conf
