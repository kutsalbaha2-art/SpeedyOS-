#!/bin/bash
# =======================================================
# SpeedyOS - Evrensel Linux Arayüzü (ELOY Çekirdeği)
# =======================================================

echo "⚡ SpeedyOS - Evrensel Linux Arayüzü Başlatılıyor..."

# 1. DONANIM SEGMENTİ VE FORM FAKTÖRÜ SİHİRBAZI (EN BAŞTA ÇALIŞIR)
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

GPU_INFO=$(lspci | grep -iE 'vga|3d')
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

# Picom: Yuvarlatılmış köşeler, cam bulanıklığı ve seri pencere geçişleri
mkdir -p ~/.config/picom/
cat << EOF > ~/.config/picom/picom.conf
# SpeedyOS Evrensel Linux Arayüzü - Görsel Motor
backend = "glx";
vsync = true;

# Hızlı Pencere Animasyonları (Solma/Açılma)
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

# Masaüstü Ortamına Göre Yüzen Görev Çubuğu ve Hızlı Animasyon Ayarı
if pgrep -x "plasmashell" > /dev/null; then
    echo "💠 KDE Plasma Algılandı: Yüzen Panel ve Hızlı Animasyonlar Uygulanıyor..."
    KWRITE=$(command -v kwriteconfig6 || command -v kwriteconfig5)
    if [ -n "$KWRITE" ]; then
        # Animasyon hızını 3 kat hızlandır (0.35 çarpanı)
        $KWRITE --file kdeglobals --group KDE --key AnimationDurationFactor "$ANIM_SPEED"
        # Koyu tema ve Papirus ikon seti
        $KWRITE --file kdeglobals --group Icons --key Theme "Papirus-Dark"
        # KDE panellerini yüzen (floating) moda al
        sed -i 's/floating=0/floating=1/g' ~/.config/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null || true
    fi
else
    echo "Dock Motoru (Plank) Yüzen Görev Çubuğu Olarak Kuruluyor..."
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
    # GTK Uygulamaları için Koyu Tema ve Papirus İkonlar
    gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null || true
    nohup plank >/dev/null 2>&1 &
fi

# 5. RAM, AĞ (TCP BBR), zRAM VE DISK ÖNBELLEK MODÜLÜ
echo "⚡ Çekirdek, zRAM ve Ağ Hızlandırma Katmanı Uygulanıyor..."
cat << 'EOF' | sudo tee /etc/sysctl.d/99-speedyos.conf > /dev/null
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.dirty_writeback_centisecs = 1500
vm.swappiness = 10
vm.vfs_cache_pressure = 50
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

# Eski PC HDD Modülü (Sadece Segment 1 seçilirse)
if [ "$SEGMENT_CHOICE" -eq 1 ]; then
    READ_AHEAD=$([ "$TYPE_CHOICE" -eq 1 ] && echo 2048 || echo 1024)
    for dev in /sys/block/sd*/queue/read_ahead_kb; do
        [ -f "$dev" ] && echo "$READ_AHEAD" | sudo tee "$dev" > /dev/null
    done
fi

# Dokunmatik Ekran Modülü (Sadece Tür 3 seçilirse)
if [ "$TYPE_CHOICE" -eq 3 ]; then
    install_pkg touchegg xserver-xorg-input-wacom xserver-xorg-input-libinput
    sudo systemctl enable --now touchegg 2>/dev/null || true
fi

# zRAM Sıkıştırma Motoru
if ! grep -q "zram" /proc/swaps 2>/dev/null; then
    sudo modprobe zram num_devices=1 2>/dev/null || true
    if [ -f /sys/block/zram0/comp_algorithm ]; then
        echo zstd | sudo tee /sys/block/zram0/comp_algorithm > /dev/null
        echo "$ZRAM_SIZE" | sudo tee /sys/block/zram0/disksize > /dev/null
        sudo mkswap /dev/zram0 > /dev/null 2>&1 || true
        sudo swapon -p 32767 /dev/zram0 > /dev/null 2>&1 || true
    fi
fi

# 4GB Disk Önbellek (Swap) Dosyası
CACHE_FILE="/speedyos_cache.bin"
if [ ! -f "$CACHE_FILE" ]; then
    sudo dd if=/dev/zero of="$CACHE_FILE" bs=1M count=4096 status=progress
    sudo chmod 600 "$CACHE_FILE"
    sudo mkswap "$CACHE_FILE"
fi
swapon --show | grep -q "$CACHE_FILE" || sudo swapon -p 10 "$CACHE_FILE" 2>/dev/null

# İşlemci Performans Modu ve Disk Zamanlayıcı
for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "$gov" ] && echo "performance" | sudo tee "$gov" > /dev/null
done

for sched in /sys/block/*/queue/scheduler; do
    if [ -f "$sched" ]; then
        grep -q "bfq" "$sched" && echo "bfq" | sudo tee "$sched" > /dev/null || \
        (grep -q "mq-deadline" "$sched" && echo "mq-deadline" | sudo tee "$sched" > /dev/null)
    fi
done

sudo sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/' /etc/systemd/system.conf
sudo sysctl --system > /dev/null 2>&1

# 6. ARKA PLAN DONDURUCU MOTORU
speedyos_freezer_engine() {
    EXCLUDE_LIST="Xorg|Xwayland|systemd|dbus|pipewire|pulseaudio|wireplumber|bash|xdotool|xprop|plank|plasmashell|kwin"
    IS_FROZEN=0
    while true; do
        ACTIVE_WIN=$(xdotool getactivewindow 2>/dev/null)
        ACTIVE_PID=$(xdotool getwindowpid "$ACTIVE_WIN" 2>/dev/null)
        IS_FULLSCREEN=$(xprop -id "$ACTIVE_WIN" _NET_WM_STATE 2>/dev/null | grep -i "FULLSCREEN")

        if [ -n "$IS_FULLSCREEN" ] && [ -n "$ACTIVE_PID" ]; then
            if [ "$IS_FROZEN" -eq 0 ]; then
                for pid in $(ps -u "$USER" -o pid,comm | grep -vE "$EXCLUDE_LIST" | awk '{print $1}'); do
                    [ "$pid" != "$ACTIVE_PID" ] && [ "$pid" != "$$" ] && kill -STOP "$pid" 2>/dev/null
                done
                sudo sysctl vm.drop_caches=3 >/dev/null 2>&1
                IS_FROZEN=1
            fi
        elif [ "$IS_FROZEN" -eq 1 ]; then
            for pid in $(ps -u "$USER" -o pid,comm | grep -vE "$EXCLUDE_LIST" | awk '{print $1}'); do
                kill -CONT "$pid" 2>/dev/null
            done
            IS_FROZEN=0
        fi
        sleep 2
    done
}

speedyos_freezer_engine & >/dev/null 2>&1
echo "🎉 SpeedyOS - Evrensel Linux Arayüzü Başarıyla Kuruldu!"
