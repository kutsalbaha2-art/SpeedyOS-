#!/bin/bash
# =====================================================================
# SpeedyOS ELOY - Bağımsız HDD I/O Optimizasyon Modülü (hdd.sh)
# GitHub: kutsalbaha2-art / SpeedyOS-
# =====================================================================

set -e

echo "⚡ SpeedyOS ELOY - HDD I/O Optimizasyon Motoru Başlatılıyor..."

# Root yetkisi kontrolü
if [ "$EUID" -ne 0 ]; then
  echo "❌ Lütfen bu betiği root yetkisiyle çalıştırın: sudo ./hdd.sh"
  exit 1
fi

echo -e "\n💾 HDD Türünü / Cihaz Tipini Seçin:"
echo "1) Laptop HDD (5400 RPM / 100 MB/s Hedefi)"
echo "2) Masaüstü HDD (7200 RPM / 200 MB/s Hedefi)"

# Terminal klavyesine kilitlenme (< /dev/tty)
read -p "Seçiminiz (1/2): " HDD_TYPE < /dev/tty

if [ "$HDD_TYPE" -eq 2 ]; then
    echo -e "\n⚙️ Masaüstü HDD Profili Yapılandırılıyor (200 MB/s)..."
    
    # Read-Ahead (Önden Okuma): 2048 KB (2MB)
    for dev in /sys/block/sd*/queue/read_ahead_kb; do
        [ -f "$dev" ] && echo 2048 | sudo tee "$dev" > /dev/null
    done
    
    cat << 'EOF' | sudo tee /etc/sysctl.d/98-speedyos-hdd.conf > /dev/null
vm.dirty_background_ratio = 8
vm.dirty_ratio = 16
vm.dirty_writeback_centisecs = 1000
EOF

else
    echo -e "\n⚙️ Laptop HDD Profili Yapılandırılıyor (100 MB/s)..."
    
    # Read-Ahead (Önden Okuma): 1024 KB (1MB - Darboğaz Önleyici)
    for dev in /sys/block/sd*/queue/read_ahead_kb; me
        [ -f "$dev" ] && echo 1024 | sudo tee "$dev" > /dev/null
    done
    
    cat << 'EOF' | sudo tee /etc/sysctl.d/98-speedyos-hdd.conf > /dev/null
vm.dirty_background_ratio = 3
vm.dirty_ratio = 8
vm.dirty_writeback_centisecs = 500
EOF

fi

# BFQ Disk Zamanlayıcısı Kitleme
echo "⚙️ Disk İğne Zamanlayıcısı (BFQ Scheduler) Aktif Ediliyor..."
for sched in /sys/block/sd*/queue/scheduler; do
    if [ -f "$sched" ] && grep -q "bfq" "$sched"; then
        echo "bfq" | sudo tee "$sched" > /dev/null
    fi
done

sudo sysctl --system > /dev/null 2>&1
echo -e "\n🚀 HDD I/O Optimizasyonu Başarıyla Uygulandı!"
