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

# 2. EVRENSEL DAĞITIM TABANI TESPİTİ (/etc/os-release STANDARDI)
OS_CHECK=""
if [ -r /etc/os-release ]; then
    . /etc/os-release
    OS_CHECK=$(echo "${ID}${ID_LIKE}" | tr '[:upper:]' '[:lower:]')
fi

if echo "$OS_CHECK" | grep -qE "arch|endeavouros|manjaro|cachyos|garuda"; then
    DISTRO="Arch"
    sudo pacman -Syy --noconfirm
elif echo "$OS_CHECK" | grep -qE "debian|ubuntu|mint|pop|kali|pardus|zorin|elementary"; then
    DISTRO="Debian"
    sudo apt-get update
elif echo "$OS_CHECK" | grep -qE "fedora|rhel|centos|rocky|almalinux|nobara"; then
    DISTRO="Fedora"
    sudo dnf check-update || true
elif echo "$OS_CHECK" | grep -qE "suse|opensuse"; then
    DISTRO="openSUSE"
    sudo zypper refresh
elif echo "$OS_CHECK" | grep -qE "void"; then
    DISTRO="Void"
    sudo xbps-install -S
else
    DISTRO="Bilinmeyen"
fi
echo "📌 Algılanan Sistem Tabanı: $DISTRO (${PRETTY_NAME:-Linux})"

# Dağıtımlar Arası Ortak Paket Kurucu
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

# 3. TABANA ÖZEL BAĞIMLILIKLAR, GÜÇ YÖNETİMİ VE GPU SÜRÜCÜLERİ
echo "🔋 Tabana Özel Paketler, Güç Yönetimi ve GPU Yapılandırılıyor..."
install_pkg python3 xdotool brightnessctl ufw rkhunter

case "$DISTRO" in
    Arch)
        install_pkg tk libpulse xorg-xprop xorg-xdpyinfo clamav auto-cpufreq
        ;;
    Debian)
        install_pkg python3-tk pulseaudio-utils x11-utils clamav clamav-freshclam auto-cpufreq
        ;;
    Fedora)
        install_pkg python3-tkinter pulseaudio-utils xprop xdpyinfo clamav clamav-update auto-cpufreq
        ;;
    openSUSE)
        install_pkg python3-tk pulseaudio-utils xprop xdpyinfo clamav
        ;;
    Void)
        install_pkg python3-tkinter pulseaudio-utils xprop xdpyinfo clamav
        ;;
esac
sudo auto-cpufreq --install 2>/dev/null || true

GPU_INFO=$(lspci 2>/dev/null | grep -iE 'vga|3d')
if echo "$GPU_INFO" | grep -iq "NVIDIA"; then
    echo "🚀 NVIDIA Ekran Kartı Algılandı!"
    case "$DISTRO" in
        Arch)     install_pkg nvidia nvidia-utils ;;
        Debian)   install_pkg nvidia-driver nvidia-smi ;;
        Fedora)   install_pkg akmod-nvidia ;;
        openSUSE) install_pkg nvidia-video-G06 ;;
    esac
elif echo "$GPU_INFO" | grep -iq "AMD"; then
    echo "🔴 AMD GPU Algılandı!"
    case "$DISTRO" in
        Arch)     install_pkg vulkan-radeon ;;
        Debian)   install_pkg mesa-vulkan-drivers ;;
        Fedora)   install_pkg mesa-vulkan-drivers ;;
        openSUSE) install_pkg libvulkan_radeon ;;
        Void)     install_pkg mesa-vulkan-radeon ;;
    esac
fi

sudo chmod a+rw /sys/class/backlight/*/brightness 2>/dev/null || true
sudo chmod a+rw /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
cat << 'EOF' | sudo tee /etc/udev/rules.d/61-speedyos-controls.rules > /dev/null
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chmod a+rw /sys/class/backlight/%k/brightness"
EOF
sudo udevadm control --reload-rules 2>/dev/null || true

# 4. SAĞ & SOL AKILLI PANELLERİ (SPEEDYOS HUD & TEK TUŞ AÇ-KAPA MOTORU)
echo "🎛️ Sağ Kontrol Merkezi & Sol Sistem Monitörü Oluşturuluyor..."
cat << 'EOF' | sudo tee /usr/local/bin/speedyos-hud.py > /dev/null
#!/usr/bin/env python3
import sys, os, glob, shutil, subprocess
import tkinter as tk

MODE = sys.argv[1] if len(sys.argv) > 1 else "right"

root = tk.Tk()
root.title("SpeedyOS_HUD_Right" if MODE == "right" else "SpeedyOS_HUD_Left")
root.attributes("-topmost", True)
try:
    root.attributes("-alpha", 0.95)
except Exception:
    pass

BG = "#0d0e14"
CARD = "#161822"
ACCENT = "#e11d48"
GOLD = "#facc15"
FG = "#f3f4f6"
MUTED = "#9ca3af"

root.configure(bg=ACCENT)
frame = tk.Frame(root, bg=BG, padx=16, pady=14)
frame.pack(fill="both", expand=True, padx=2, pady=2)

sw = root.winfo_screenwidth()
sh = root.winfo_screenheight()
hovered = {"active": False}

def close_win(event=None):
    try:
        root.destroy()
    except Exception:
        pass

def on_enter(event=None):
    hovered["active"] = True

def check_leave(event=None):
    if not hovered["active"]:
        return
    try:
        px, py = root.winfo_pointerxy()
        wx, wy = root.winfo_rootx(), root.winfo_rooty()
        ww, wh = root.winfo_width(), root
