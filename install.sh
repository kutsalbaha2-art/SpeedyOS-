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

# 1. SpeedyOs betik dosyasını oluştur / aç
nano speedyos.sh

# (Açılan ekrana kodları yapıştırdıktan sonra CTRL+O -> Enter -> CTRL+X ile kaydet ve çık)

# 2. Betiğe çalıştırma (executable) yetkisi ver
chmod +x speedyos.sh

# 3. Disk önbelleği ve dondurucu motorunu yönetici (root) yetkisiyle başlat
sudo ./speedyos.sh

echo "🚀 SpeedyOs Eski Optimizasyonlar + Konsol Modu + Disk Önbelleğiyle Aktif Edildi!"

sudo sysctl --system

echo "🎉 SpeedyOs Başarıyla Kuruldu! Sisteminiz Ateş Ediyor."

# =====================================================================
#  SPEEDYOS - EK PERFORMANS & SİSTEM OPTİMİZASYON BLOĞU
# =====================================================================

echo -e "\n[+] SpeedyOS Ek Performans Ayarları Uygulanıyor..."

# 1. RAM ve Ağ Çekirdek Ayarları (Sysctl Yapılandırması)
cat << 'EOF' | sudo tee /etc/sysctl.d/99-speedyos.conf > /dev/null
# RAM optimizasyonu (Diske yazmayı geciktir, RAM'de tut)
vm.swappiness=10
vm.vfs_cache_pressure=50

# Google TCP BBR Ağ / Ping Düşürme Algoritması
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

# Ayarları sisteme anında uygula
sudo sysctl --system > /dev/null 2>&1

# 2. İşlemci Performans Modu (Tüm Çekirdekleri Uyar)
for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [ -f "$gov" ]; then
        echo "performance" | sudo tee "$gov" > /dev/null
    fi
done

# 3. SSD ve NVMe Disk Okuma Zamanlayıcısı (I/O Scheduler)
for sched in /sys/block/*/queue/scheduler; do
    if [ -f "$sched" ]; then
        if grep -q "bfq" "$sched"; then
            echo "bfq" | sudo tee "$sched" > /dev/null
        elif grep -q "mq-deadline" "$sched"; then
            echo "mq-deadline" | sudo tee "$sched" > /dev/null
        fi
    fi
done

# 4. Hızlı Kapanış (Takılı Kalan Servislerin Kapanma Bekleme Süresini Düşür)
sudo sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/' /etc/systemd/system.conf

echo "[✓] SpeedyOS ek optimizasyonları başarıyla uygulandı!"

# =====================================================================
# SPEEDYOS ELOY v0.5 - EK DONANIM & SEGMENT MODÜLÜ
# (Bu bloğu mevcut install.sh dosyanızın EN ALTINA yapıştırabilirsiniz)
# =====================================================================

echo -e "\n======================================================="
echo " 🚀 SpeedyOS ELOY Donanım Sihirbazı & Ek Optimizasyonlar"
echo "======================================================="

# 1. SEGMENT VE TÜR SEÇİMİ
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

# 2. SEGMENTE GÖRE DEĞİŞKENLERİN ATANMASI
case $SEGMENT_CHOICE in
    1)
        echo -e "\n[+] Düşük Donanım Modu Seçildi."
        BLUR_STRENGTH=3
        ZRAM_SIZE="2G"
        ;;
    2)
        echo -e "\n[+] Orta Segment Modu Seçildi."
        BLUR_STRENGTH=6
        ZRAM_SIZE="4G"
        ;;
    3)
        echo -e "\n[+] Oyuncu / Yüksek Performans Modu Seçildi."
        BLUR_STRENGTH=10
        ZRAM_SIZE="6G"
        ;;
    *)
        BLUR_STRENGTH=6
        ZRAM_SIZE="4G"
        ;;
esac

# 3. ESKİ PC HDD I/O OPTİMİZASYON MODÜLÜ (100 MB/s vs 200 MB/s)
if [ "$SEGMENT_CHOICE" -eq 1 ]; then
    echo -e "\n[+] Eski Donanım HDD I/O Optimizasyonu Uygulanıyor..."
    
    if [ "$TYPE_CHOICE" -eq 1 ]; then
        echo "⚙️ Masaüstü HDD Profili Yapılandırılıyor (200 MB/s HEDEFİ)..."
        for dev in /sys/block/sd*/queue/read_ahead_kb; do
            [ -f "$dev" ] && echo 2048 | sudo tee "$dev" > /dev/null
        done
        
        cat << 'EOF' | sudo tee /etc/sysctl.d/98-speedyos-hdd.conf > /dev/null
vm.dirty_background_ratio = 8
vm.dirty_ratio = 16
vm.dirty_writeback_centisecs = 1000
EOF
    else
        echo "⚙️ Laptop HDD Profili Yapılandırılıyor (100 MB/s HEDEFİ)..."
        for dev in /sys/block/sd*/queue/read_ahead_kb; do
            [ -f "$dev" ] && echo 1024 | sudo tee "$dev" > /dev/null
        done
        
        cat << 'EOF' | sudo tee /etc/sysctl.d/98-speedyos-hdd.conf > /dev/null
vm.dirty_background_ratio = 3
vm.dirty_ratio = 8
vm.dirty_writeback_centisecs = 500
EOF
    fi
fi

# 4. DOKUNMATİK SÜRÜCÜ DOKUNUŞU (EĞER DOKUNMATİK SEÇİLDİYSE)
if [ "$TYPE_CHOICE" -eq 3 ]; then
    echo -e "\n[+] Dokunmatik Ekran Sürücüleri ve Jest Motoru Yükleniyor..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y touchegg xserver-xorg-input-wacom xserver-xorg-input-libinput 2>/dev/null || true
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm touchegg 2>/dev/null || true
    fi
    sudo systemctl enable --now touchegg 2>/dev/null || true
fi

# 5. zRAM SIKIŞTIRMA VE AYARLARIN UYGULANMASI
if ! grep -q "zram" /proc/swaps 2>/dev/null; then
    echo -e "\n[+] zRAM ZSTD Sıkıştırma Motoru Aktif Ediliyor ($ZRAM_SIZE)..."
    sudo modprobe zram num_devices=1 2>/dev/null || true
    if [ -f /sys/block/zram0/comp_algorithm ]; then
        echo zstd | sudo tee /sys/block/zram0/comp_algorithm > /dev/null
        echo "$ZRAM_SIZE" | sudo tee /sys/block/zram0/disksize > /dev/null
        sudo mkswap /dev/zram0 > /dev/null 2>&1 || true
        sudo swapon -p 32767 /dev/zram0 > /dev/null 2>&1 || true
    fi
fi

sudo sysctl --system > /dev/null 2>&1
echo -e "\n[✓] SpeedyOS ELOY Ek Donanım Modülü Başarıyla Devreye Alındı!"
