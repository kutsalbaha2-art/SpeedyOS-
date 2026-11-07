#!/bin/bash
# =====================================================================
# SpeedyOS ELOY - Bağımsız SSD & NVMe Optimizasyon Modülü (SSD.sh)
# GitHub: kutsalbaha2-art / SpeedyOS-
# =====================================================================

set -e

echo "⚡ SpeedyOS ELOY - SSD/NVMe Optimizasyon Motoru Başlatılıyor..."

# Root yetkisi kontrolü
if [ "$EUID" -ne 0 ]; then
  echo "❌ Lütfen bu betiği root yetkisiyle çalıştırın: sudo ./SSD.sh"
  exit 1
fi

echo -e "\n💽 SSD Sürücü Türünü Seçin:"
echo "1) NVMe M.2 SSD (Yüksek Hızlı PCIe SSD - Örn: Excalibur G870)"
echo "2) SATA 3 SSD (Standart 2.5 inç SSD / 500-550 MB/s)"

# Terminal klavyesine kilitlenme (< /dev/tty)
read -p "Seçiminiz (1/2): " SSD_TYPE < /dev/tty

# ---------------------------------------------------------------------
# 1. I/O SCHEDULER & READ-AHEAD AYARLARI
# ---------------------------------------------------------------------
if [ "$SSD_TYPE" -eq 1 ]; then
    echo -e "\n⚙️ NVMe M.2 SSD Profili Yapılandırılıyor..."
    
    # NVMe sürücülerde mekanik gecikme olmadığı için scheduler 'none' yapılır
    for sched in /sys/block/nvme*/queue/scheduler; do
        [ -f "$sched" ] && echo "none" > "$sched" 2>/dev/null || true
    done
    
    # NVMe için Read-Ahead (Önden Okuma): 256 KB (Zero Seek Latency)
    for dev in /sys/block/nvme*/queue/read_ahead_kb; do
        [ -f "$dev" ] && echo 256 > "$dev" 2>/dev/null || true
    done
else
    echo -e "\n⚙️ SATA 3 SSD Profili Yapılandırılıyor..."
    
    # SATA SSD için mq-deadline veya none zamanlayıcısı
    for sched in /sys/block/sd*/queue/scheduler; do
        if [ -f "$sched" ]; then
            if grep -q "none" "$sched"; then
                echo "none" > "$sched" 2>/dev/null || true
            elif grep -q "mq-deadline" "$sched"; then
                echo "mq-deadline" > "$sched" 2>/dev/null || true
            fi
        fi
    done
    
    # SATA SSD için Read-Ahead: 512 KB
    for dev in /sys/block/sd*/queue/read_ahead_kb; do
        [ -f "$dev" ] && echo 512 > "$dev" 2>/dev/null || true
    done
fi

# ---------------------------------------------------------------------
# 2. SSD ÖMRÜNÜ UZATAN VE HÜCRE AŞINMASINI ÖNLEYEN ÇEKİRDEK AYARLARI
# ---------------------------------------------------------------------
echo "⚙️ SSD Hücre Ömrü ve Çekirdek Önbellek Parametreleri Yazılıyor..."
cat << 'EOF' > /etc/sysctl.d/97-speedyos-ssd.conf
# SWAP kullanımını düşürerek SSD'ye sürekli veri yazılmasını engeller
vm.swappiness = 10

# Inode/Dizin önbelleğini RAM'de tutar
vm.vfs_cache_pressure = 50

# Disk yazma geciktirmesi (Sürekli diske yazmak yerine 15 sn biriktirir)
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.dirty_writeback_centisecs = 1500
EOF

# ---------------------------------------------------------------------
# 3. FSTRIM (TRIM) OTOMASYONU VE ANLIK HÜCRE TEMİZLİĞİ
# ---------------------------------------------------------------------
echo "🧹 TRIM Servisi Aktif Ediliyor ve Ölü Hücreler Temizleniyor..."
systemctl enable --now fstrim.timer 2>/dev/null || true
fstrim -av 2>/dev/null || true

sysctl --system > /dev/null 2>&1
echo -e "\n🚀 SSD/NVMe Optimizasyonu Başarıyla Uygulandı ve Kilitlendi!"
