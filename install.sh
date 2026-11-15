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
install_pkg auto-cpufreq xdotool xorg-xprop
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

# 4. YÜZEN GÖREV ÇUBUĞU VE HIZLI ANİMASYONLAR (SİMGELERE DOKUNMAZ)
echo "🎨 Yüzen Görev Çubuğu ve Hızlı Animasyonlar Aktif Ediliyor..."
if pgrep -x "plasmashell" > /dev/null; then
    echo "💠 KDE Plasma Algılandı: Yüzen Panel ve Hızlı Animasyonlar Uygulanıyor..."
    KWRITE=$(command -v kwriteconfig6 || command -v kwriteconfig5)
    if [ -n "$KWRITE" ]; then
        $KWRITE --file kdeglobals --group KDE --key AnimationDurationFactor "$ANIM_SPEED"
    fi
    APPLET_RC="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    if [ -f "$APPLET_RC" ]; then
        sed -i '/^floating=/d' "$APPLET_RC"
        sed -i 's/^plugin=org.kde.panel/plugin=org.kde.panel\nfloating=1/' "$APPLET_RC"
    fi
    # KWin animasyonlarını ve Plasma kabuğunu anında yenile
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    systemctl --user restart plasma-plasmashell.service 2>/dev/null || (nohup plasmashell --replace >/dev/null 2>&1 &)
else
    echo "🪟 Hafif Masaüstü Algılandı: Plank Yüzen Çubuk ve Picom Başlatılıyor..."
    install_pkg picom plank
    mkdir -p ~/.config/picom/ ~/.config/autostart/
    cat << EOF > ~/.config/picom/picom.conf
backend = "glx";
vsync = true;
fading = true;
fade-in-step = 0.08;
fade-out-step = 0.08;
fade-delta = 3;
blur-background = true;
blur-method = "dual_kawase";
blur-strength = ${BLUR_STRENGTH};
corner-radius = 12;
rounded-corners-exclude = [ "window_type = 'desktop'" ];
EOF
    cat << 'EOF' > ~/.config/autostart/speedyos-dock.desktop
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=SpeedyOS Yüzen Görev Çubuğu
EOF
    pkill -x picom 2>/dev/null || true
    pkill -x plank 2>/dev/null || true
    nohup picom -b >/dev/null 2>&1 &
    nohup plank >/dev/null 2>&1 &
fi

# 5. RAM, AĞ (TCP BBR), zRAM, KALICI HDD VE DISK ÖNBELLEK MODÜLÜ
echo "⚡ Çekirdek, zRAM, Kalıcı HDD ve Ağ Hızlandırma Katmanı Uygulanıyor..."
cat << 'EOF' | sudo tee /etc/sysctl.d/99-speedyos.conf > /dev/null
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.dirty_writeback_centisecs = 1500
vm.swappiness = 10
vm.vfs_cache_pressure = 50
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

if [ "$SEGMENT_CHOICE" -eq 1 ]; then
    READ_AHEAD=$([ "$TYPE_CHOICE" -eq 1 ] && echo 2048 || echo 1024)
    cat << EOF | sudo tee /etc/udev/rules.d/60-speedyos-hdd.rules > /dev/null
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/read_ahead_kb}="$READ_AHEAD", ATTR{queue/scheduler}="bfq"
EOF
    sudo udevadm control --reload-rules && sudo udevadm trigger
fi

if [ "$TYPE_CHOICE" -eq 3 ]; then
    install_pkg touchegg xserver-xorg-input-wacom xserver-xorg-input-libinput
    sudo systemctl enable --now touchegg 2>/dev/null || true
fi

if ! grep -q "zram" /proc/swaps 2>/dev/null; then
    sudo modprobe zram num_devices=1 2>/dev/null || true
    if [ -f /sys/block/zram0/comp_algorithm ]; then
        echo zstd | sudo tee /sys/block/zram0/comp_algorithm > /dev/null
        echo "$ZRAM_SIZE" | sudo tee /sys/block/zram0/disksize > /dev/null
        sudo mkswap /dev/zram0 > /dev/null 2>&1 || true
        sudo swapon -p 32767 /dev/zram0 > /dev/null 2>&1 || true
    fi
fi

CACHE_FILE="/speedyos_cache.bin"
if [ ! -f "$CACHE_FILE" ]; then
    sudo dd if=/dev/zero of="$CACHE_FILE" bs=1M count=4096 status=progress
    sudo chmod 600 "$CACHE_FILE"
    sudo mkswap "$CACHE_FILE"
fi
swapon --show | grep -q "$CACHE_FILE" || sudo swapon -p 10 "$CACHE_FILE" 2>/dev/null

for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "$gov" ] && echo "performance" | sudo tee "$gov" > /dev/null
done

for sched in /sys/block/*/queue/scheduler; do
    if [ -f "$sched" ]; then
        grep -q "bfq" "$sched" && echo "bfq" | sudo tee "$sched" > /dev/null || \
        (grep -q "mq-deadline" "$sched" && echo "mq-deadline" | sudo tee "$sched" > /dev/null)
    fi
done

if [ -f /etc/systemd/system.conf ]; then
    sudo sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/' /etc/systemd/system.conf
fi

sudo sysctl --system > /dev/null 2>&1

# 6. ARKA PLAN DONDURUCU MOTORU
speedyos_freezer_engine() {
    EXCLUDE_LIST="Xorg|Xwayland|systemd|dbus|pipewire|pulseaudio|wireplumber|bash|xdotool|xprop|plank|plasmashell|kwin|picom"
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
