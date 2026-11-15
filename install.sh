#!/bin/bash
# =======================================================
# SpeedyOS - Evrensel Linux Arayüzü (Tam Kabuk Sürümü)
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

# 4. SPEEDYOS ÖZEL İŞLETİM SİSTEMİ KABUĞU VE TEMASI
echo "🎨 SpeedyOS Özel Arayüz Kabuğu İnşa Ediliyor..."

# Özel SpeedyOS Vektörel Duvar Kağıdı Oluştur
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
  <path d="M0 820 Q 480 680 960 790 T 1920 720 L 1920 1080 L 0 1080 Z" fill="url(#accent)"/>
</svg>
EOF

# Özel SpeedyOS Obsidyen-Kızıl-Altın Renk Şeması
cat << 'EOF' > "$HOME/.local/share/color-schemes/SpeedyOS.colors"
[General]
ColorScheme=SpeedyOS
Name=SpeedyOS Obsidian

[Colors:Window]
BackgroundNormal=13,14,20
BackgroundAlternate=20,22,31
ForegroundNormal=243,244,246
ForegroundInactive=156,163,175
DecorationFocus=225,29,72
DecorationHover=250,204,21

[Colors:View]
BackgroundNormal=10,11,16
BackgroundAlternate=17,19,27
ForegroundNormal=243,244,246

[Colors:Selection]
BackgroundNormal=225,29,72
ForegroundNormal=255,255,255

[WM]
activeBackground=13,14,20
activeForeground=250,204,21
inactiveBackground=10,11,16
inactiveForeground=107,114,128
EOF

if pgrep -x "plasmashell" > /dev/null; then
    echo "💠 KDE Plasma Algılandı: Çift Barlı SpeedyOS Kabuğu Kuruluyor..."
    KWRITE=$(command -v kwriteconfig6 || command -v kwriteconfig5)
    if [ -n "$KWRITE" ]; then
        $KWRITE --file kdeglobals --group KDE --key AnimationDurationFactor "$ANIM_SPEED"
        $KWRITE --file kwinrc --group Plugins --key blurEnabled true
        $KWRITE --file kwinrc --group Plugins --key slideEnabled true
        $KWRITE --file kwinrc --group Effect-blur --key BlurStrength "$BLUR_STRENGTH"
    fi

    plasma-apply-colorscheme SpeedyOS 2>/dev/null || true
    plasma-apply-wallpaperimage "$WALLPAPER_PATH" 2>/dev/null || true

    # Eski paneli kaldırıp Üst Durum Çubuğu + Alt Yüzen Dock oluştur
    PLASMA_SCRIPT='
    panels().forEach(p => p.remove());

    var topBar = new Panel("org.kde.panel");
    topBar.location = "top";
    topBar.height = 28;
    topBar.floating = true;
    topBar.addWidget("org.kde.plasma.kicker");
    topBar.addWidget("org.kde.plasma.appmenu");
    topBar.addWidget("org.kde.plasma.panelspacer");
    topBar.addWidget("org.kde.plasma.digitalclock");
    topBar.addWidget("org.kde.plasma.panelspacer");
    topBar.addWidget("org.kde.plasma.systemtray");

    var dock = new Panel("org.kde.panel");
    dock.location = "bottom";
    dock.height = 54;
    dock.floating = true;
    dock.alignment = "center";
    try { dock.lengthMode = "fit"; } catch(e) {}
    dock.addWidget("org.kde.plasma.icontasks");
    dock.addWidget("org.kde.plasma.trash");
    '
    busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$PLASMA_SCRIPT" >/dev/null 2>&1 || true
    busctl --user call org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
else
    echo "🪟 Hafif Masaüstü Algılandı: Yüzen Dock ve Cam Efektleri Kuruluyor..."
    install_pkg picom plank feh
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
corner-radius = 14;
rounded-corners-exclude = [ "window_type = 'desktop'" ];
EOF
    cat << 'EOF' > ~/.config/autostart/speedyos-dock.desktop
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=SpeedyOS Yüzen Dock
EOF
    feh --bg-fill "$WALLPAPER_PATH" 2>/dev/null || true
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

# 7. SPEEDYWALL (0 MB RAM GÜVENLİK DUVARI) & SPEEDYSECURE (HAFİF ANTİVİRÜS)
echo "🛡️ SpeedyWall ve SpeedySecure Güvenlik Katmanı Kuruluyor..."
install_pkg ufw clamav rkhunter

# Arka planda 1.5 GB RAM yiyen ağır ClamAV servisini kapat (Sadece talep anında çalışsın)
sudo systemctl disable --now clamav-daemon 2>/dev/null || true

# SpeedyWall: Varsayılan olarak dışarıdan gelen tüm bağlantıları engelle, çıkışı serbest bırak
sudo ufw default deny incoming >/dev/null 2>&1 || true
sudo ufw default allow outgoing >/dev/null 2>&1 || true
sudo ufw --force enable >/dev/null 2>&1 || true

# SpeedyWall Terminal Komutu Oluştur
cat << 'EOF' | sudo tee /usr/local/bin/speedywall > /dev/null
#!/bin/bash
case "$1" in
    aktif)  sudo ufw --force enable && echo "🛡️ SpeedyWall: Kalkan Aktif (0 MB RAM)" ;;
    kapat)  sudo ufw disable && echo "⚠️ SpeedyWall: Devre Dışı" ;;
    durum)  sudo ufw status verbose ;;
    *)      echo "Kullanım: speedywall [aktif | kapat | durum]" ;;
esac
EOF
sudo chmod +x /usr/local/bin/speedywall

# SpeedySecure Terminal Komutu Oluştur
cat << 'EOF' | sudo tee /usr/local/bin/speedysecure > /dev/null
#!/bin/bash
case "$1" in
    tara)
        TARGET="${2:-$HOME/Downloads}"
        echo "🔍 SpeedySecure Taraması Başlatılıyor: $TARGET"
        clamscan -r --bell -i "$TARGET"
        ;;
    guncelle)
        echo "🔄 Virüs Veritabanı Güncelleniyor..."
        sudo freshclam
        ;;
    sistem)
        echo "🧬 Çekirdek ve Rootkit Denetimi Yapılıyor..."
        sudo rkhunter --check --sk
        ;;
    *)
        echo "Kullanım: speedysecure [tara <klasor> | guncelle | sistem]"
        ;;
esac
EOF
sudo chmod +x /usr/local/bin/speedysecure
echo "🎉 SpeedyOS - Evrensel Linux Arayüzü Tam Kabuk Modunda Kuruldu!"
