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

# 2. PAKET YÖNETİCİSİ TESPİTİ VE ÇAKIŞMA KORUMALI KURULUM
OS_CHECK=""
[ -r /etc/os-release ] && . /etc/os-release && OS_CHECK=$(echo "${ID}${ID_LIKE}" | tr '[:upper:]' '[:lower:]')

if echo "$OS_CHECK" | grep -qE "arch|endeavouros|manjaro|cachyos|garuda"; then
    DISTRO="Arch"; sudo pacman -Syy --noconfirm
elif echo "$OS_CHECK" | grep -qE "debian|ubuntu|mint|pop|kali|pardus|zorin|elementary"; then
    DISTRO="Debian"; sudo apt-get update
elif echo "$OS_CHECK" | grep -qE "fedora|rhel|centos|rocky|almalinux|nobara"; then
    DISTRO="Fedora"; sudo dnf check-update || true
elif echo "$OS_CHECK" | grep -qE "suse|opensuse"; then
    DISTRO="openSUSE"; sudo zypper refresh
elif echo "$OS_CHECK" | grep -qE "void"; then
    DISTRO="Void"; sudo xbps-install -S
else
    DISTRO="Bilinmeyen"
fi

install_pkg() {
    for pkg in "$@"; do
        case "$DISTRO" in
            Arch)     sudo pacman -S --noconfirm --needed --overwrite '*' "$pkg" 2>/dev/null || true ;;
            Debian)   sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" 2>/dev/null || true ;;
            Fedora)   sudo dnf install -y "$pkg" 2>/dev/null || true ;;
            openSUSE) sudo zypper install -y "$pkg" 2>/dev/null || true ;;
            Void)     sudo xbps-install -y "$pkg" 2>/dev/null || true ;;
        esac
    done
}

# 3. TEMEL BAĞIMLILIKLAR, GÜÇ YÖNETİMİ VE GPU SÜRÜCÜLERİ
echo "🔋 Temel Sistem Araçları ve Donanım Sürücüleri Kuruluyor..."
install_pkg python3 xdotool brightnessctl ufw rkhunter

case "$DISTRO" in
    Arch)     install_pkg tk libpulse xorg-xprop xorg-xdpyinfo clamav auto-cpufreq ;;
    Debian)   install_pkg python3-tk pulseaudio-utils x11-utils clamav clamav-freshclam auto-cpufreq ;;
    Fedora)   install_pkg python3-tkinter pulseaudio-utils xprop xdpyinfo clamav clamav-update auto-cpufreq ;;
    openSUSE) install_pkg python3-tk pulseaudio-utils xprop xdpyinfo clamav ;;
    Void)     install_pkg python3-tkinter pulseaudio-utils xprop xdpyinfo clamav ;;
esac
sudo auto-cpufreq --install 2>/dev/null || true

GPU_INFO=$(lspci 2>/dev/null | grep -iE 'vga|3d')
if echo "$GPU_INFO" | grep -iq "NVIDIA"; then
    [ "$DISTRO" = "Arch" ] && install_pkg nvidia nvidia-utils
    [ "$DISTRO" = "Debian" ] && install_pkg nvidia-driver nvidia-smi
    [ "$DISTRO" = "Fedora" ] && install_pkg akmod-nvidia
elif echo "$GPU_INFO" \vert{} grep -iq "AMD"; then [ "$
