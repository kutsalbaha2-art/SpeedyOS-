#!/bin/bash
# =======================================================
# SpeedyOS - Evrensel Linux Arayüzü & Güvenlik Paketi
# =======================================================

echo "⚡ SpeedyOS - Evrensel Linux Arayüzü Başlatılıyor..."

# 1. DONANIM SEGMENTİ VE FORM FAKTÖRÜ SİHİRBAZI
echo -e "\n🖥️  Bilgisayarınızın Donanım Segmentini Seçin:"
echo "1) Eski / Düşük Donanımlı Bilgisayar (RAM 4GB alti / HDD)"
echo "2) Orta Segment Bilgisayar"
echo "3) Oyuncu / Yüksek Performanslı PC (Örn: Excalibur G870)"
read -p "Seçiminiz (1/2/3): " SEGMENT_CHOICE

echo -e "\n💻 Bilgisayarınızın Form Faktörünü (Türünü) Seçin:"
echo "1) Masaüstü PC"
echo "2) Laptop / Dizüstü"
echo "3) Dokunmatik Ekranlı (2'si 1 arada / Tablet PC)"
read -p "Seçiminiz (1/2/3): " TYPE_CHOICE

case $SEGMENT_CHOICE in
    1) BLUR_STRENGTH=3; BLUR_ENABLED=false; ZRAM_SIZE="2G"; ANIM_SPEED="0.85" ;;
    2) BLUR_STRENGTH=6; BLUR_ENABLED=true; ZRAM_SIZE="4G"; ANIM_SPEED="1" ;;
    3) BLUR_STRENGTH=10; BLUR_ENABLED=true; ZRAM_SIZE="6G"; ANIM_SPEED="1" ;;
    *) BLUR_STRENGTH=6; BLUR_ENABLED=true; ZRAM_SIZE="4G"; ANIM_SPEED="1" ;;
esac

# 2. DAĞITIM TESPİTİ VE ÇAKIŞMA KORUMALI PAKET MOTORU
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
    for pkg in "$@"; do
        if [ "$DISTRO" = "Debian/Ubuntu" ]; then
            sudo apt-get install -y "$pkg" 2>/dev/null || true
        elif [ "$DISTRO" = "Arch" ]; then
            sudo pacman -S --noconfirm --needed --overwrite '*' "$pkg" 2>/dev/null || true
        elif [ "$DISTRO" = "Fedora" ]; then
            sudo dnf install -y "$pkg" 2>/dev/null || true
        fi
    done
}

# 3. GÜÇ YÖNETİMİ, SÜRÜCÜLER VE ARAYÜZ BAĞIMLILIKLARI
echo "🔋 Güç Yönetimi, GPU ve Akıllı Panel Araçları Yükleniyor..."
install_pkg auto-cpufreq xdotool xorg-xprop x11-utils python3 brightnessctl
[ "$DISTRO" = "Debian/Ubuntu" ] && install_pkg python3-tk python3-dbus python3-gi pulseaudio-utils
[ "$DISTRO" = "Arch" ] && install_pkg tk python-dbus python-gobject libpulse
[ "$DISTRO" = "Fedora" ] && install_pkg python3-tkinter python3-dbus python3-gobject pulseaudio-utils
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

sudo chmod a+rw /sys/class/backlight/*/brightness 2>/dev/null || true
sudo chmod a+rw /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
cat << 'EOF' | sudo tee /etc/udev/rules.d/61-speedyos-controls.rules > /dev/null
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chmod a+rw /sys/class/backlight/%k/brightness"
EOF
sudo udevadm control --reload-rules 2>/dev/null || true

# 4. SPEEDYOS ÖZEL İŞLETİM SİSTEMİ KABUĞU VE KWIN 6 ANİMASYON MOTORU
echo "🎨 SpeedyOS Özel Arayüz Kabuğu, Çift Panel ve Animasyonlar Kuruluyor..."

mkdir -p "$HOME/.local/share/wallpapers" "$HOME/.local/share/color-schemes"
WALLPAPER_PATH="$HOME/.local/share/wallpapers/speedyos-shell.svg"
cat << 'EOF' > "$WALLPAPER_PATH"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080">
  <defs>
    <radialGradient id="bg" cx="50%" cy="45%" r="75%">
      <stop offset="0%" stop-color="#1a1118"/>
      <stop offset="55%" stop-color="#0d0e14"/>
      <stop offset="100%" stop-color="#06070a"/>
    </radialGradient>
    <linearGradient id="accent" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#e11d48" stop-opacity="0.45"/>
      <stop offset="100%" stop-color="#facc15" stop-opacity="0.25"/>
    </linearGradient>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <circle cx="960" cy="520" r="340" fill="none" stroke="url(#accent)" stroke-width="3"/>
  <circle cx="960" cy="520" r="460" fill="none" stroke="#e11d48" stroke-opacity="0.15" stroke-width="1.5"/>
  <path d="M0 820 Q 480 680 960 790 T 1920 720 L 1920 1080 L 0 1080 Z" fill="url(#
