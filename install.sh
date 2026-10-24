# =======================================================
# 1. BURADA SENİN MEVCUT/ESKİ SPEEDYOS KODLARIN ÇALIŞIR
# (Eski kodlarını aynen burada tutabilirsin)
# =======================================================
#!/bin/bash
# =======================================================
# SpeedyOs Universal Optimizer & Hardware Driver Engine v0.3
# =======================================================

echo "⚡ SpeedyOs Evrensel Kurulum Sistemi Başlatılıyor..."

# 1. DAĞITIM TESPİTİ VE DEPO GÜNCELLEMESİ
if [ -f /etc/debian_version ]; then
    DISTRO="Debian/Ubuntu"
    echo "📌 Algılanan Dağıtım: $DISTRO"
    sudo apt-get update
elif [ -f /etc/arch-release ]; then
    DISTRO="Arch"
    echo "📌 Algılanan Dağıtım: $DISTRO"
    sudo pacman -Syy --noconfirm
elif [ -f /etc/fedora-release ]; then
    DISTRO="Fedora"
    echo "📌 Algılanan Dağıtım: $DISTRO"
    sudo dnf check-update
fi

# EVRENSEL PAKET YÜKLEME FONKSİYONU
install_pkg() {
    if [ "$DISTRO" = "Debian/Ubuntu" ]; then
        sudo apt-get install -y "$@"
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

# =======================================================
# 2. SPEEDYOS DISK ÖNBELLEK (SWAP) MODÜLÜ
# =======================================================
CACHE_FILE="/speedyos_cache.bin"
CACHE_SIZE_GB=4

if [ ! -f "$CACHE_FILE" ]; then
    echo "⚡ SpeedyOs Disk Önbellek Dosyası Oluşturuluyor (${CACHE_SIZE_GB}GB)..."
    dd if=/dev/zero of="$CACHE_FILE" bs=1M count=$((CACHE_SIZE_GB * 1024)) status=progress
    chmod 600 "$CACHE_FILE"
    mkswap "$CACHE_FILE"
fi

if ! swapon --show | grep -q "$CACHE_FILE"; then
    swapon -p 10 "$CACHE_FILE" 2>/dev/null
fi

sysctl vm.swappiness=100 >/dev/null
sysctl vm.vfs_cache_pressure=50 >/dev/null


# =======================================================
# 3. SPEEDYOS ARKA PLAN DONDURUCU MOTORU (ARKA PLANDA)
# =======================================================
speedyos_freezer_engine() {
    EXCLUDE_LIST="Xorg|Xwayland|systemd|dbus|pipewire|pulseaudio|wireplumber|bash|xdotool|xprop"
    IS_FROZEN=0

    while true; do
        ACTIVE_WIN=$(xdotool getactivewindow 2>/dev/null)
        ACTIVE_PID=$(xdotool getwindowpid "$ACTIVE_WIN" 2>/dev/null)
        IS_FULLSCREEN=$(xprop -id "$ACTIVE_WIN" _NET_WM_STATE 2>/dev/null | grep -i "FULLSCREEN")

        if [ -n "$IS_FULLSCREEN" ] && [ -n "$ACTIVE_PID" ]; then
            if [ "$IS_FROZEN" -eq 0 ]; then
                TARGETS=$(ps -u "$USER" -o pid,comm | grep -vE "$EXCLUDE_LIST" | awk '{print $1}')
                for pid in $TARGETS; do
                    if [ "$pid" != "$ACTIVE_PID" ] && [ "$pid" != "$$" ]; then
                        kill -STOP "$pid" 2>/dev/null
                    fi
                done
                sysctl vm.drop_caches=3 >/dev/null 2>&1
                IS_FROZEN=1
            fi
        else
            if [ "$IS_FROZEN" -eq 1 ]; then
                TARGETS=$(ps -u "$USER" -o pid,comm | grep -vE "$EXCLUDE_LIST" | awk '{print $1}')
                for pid in $TARGETS; do
                    kill -CONT "$pid" 2>/dev/null
                done
                IS_FROZEN=0
            fi
        fi
        sleep 2
    done
}

# Dondurucu motorunu arka planda (&) fırlatıyoruz
speedyos_freezer_engine & >/dev/null 2>&1

echo "🚀 SpeedyOs Eski Optimizasyonlar + Konsol Modu + Disk Önbelleğiyle Aktif Edildi!"

sudo sysctl --system

echo "🎉 SpeedyOs Başarıyla Kuruldu! Sisteminiz Ateş Ediyor."
