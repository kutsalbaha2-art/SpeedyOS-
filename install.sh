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
    1) BLUR_STRENGTH=3; BLUR_ENABLED=false; ZRAM_SIZE="2G"; ANIM_SPEED="0.30" ;;
    2) BLUR_STRENGTH=6; BLUR_ENABLED=true; ZRAM_SIZE="4G"; ANIM_SPEED="0.40" ;;
    3) BLUR_STRENGTH=10; BLUR_ENABLED=true; ZRAM_SIZE="6G"; ANIM_SPEED="0.40" ;;
    *) BLUR_STRENGTH=6; BLUR_ENABLED=true; ZRAM_SIZE="4G"; ANIM_SPEED="0.40" ;;
esac

# 2. DAĞITIM TESPİTİ VE TEKİL PAKET YÜKLEME MOTORU
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
            sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null || true
        elif [ "$DISTRO" = "Fedora" ]; then
            sudo dnf install -y "$pkg" 2>/dev/null || true
        fi
    done
}

# 3. GÜÇ YÖNETİMİ, SÜRÜCÜLER VE ARAYÜZ BAĞIMLILIKLARI
echo "🔋 Güç Yönetimi, GPU ve Akıllı Panel Araçları Yükleniyor..."
install_pkg auto-cpufreq xdotool xorg-xprop x11-utils python3 brightnessctl
[ "$DISTRO" = "Debian/Ubuntu" ] && install_pkg python3-tk pulseaudio-utils
[ "$DISTRO" = "Arch" ] && install_pkg tk libpulse
[ "$DISTRO" = "Fedora" ] && install_pkg python3-tkinter pulseaudio-utils
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

# Parlaklık ve CPU Güç Modunun Sağ Panelden Şifresiz Ayarlanabilmesi İçin İzinler
sudo chmod a+rw /sys/class/backlight/*/brightness 2>/dev/null || true
sudo chmod a+rw /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
cat << 'EOF' | sudo tee /etc/udev/rules.d/61-speedyos-controls.rules > /dev/null
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chmod a+rw /sys/class/backlight/%k/brightness"
EOF
sudo udevadm control --reload-rules 2>/dev/null || true

# 4. SPEEDYOS ÖZEL İŞLETİM SİSTEMİ KABUĞU VE ANİMASYON MOTORU
echo "🎨 SpeedyOS Özel Arayüz Kabuğu ve Fırlama Animasyonları Kuruluyor..."

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
    echo "💠 KDE Plasma Algılandı: Gelişmiş Kabuk ve Sihirli Lamba Animasyonları Uygulanıyor..."
    KWRITE=$(command -v kwriteconfig6 || command -v kwriteconfig5)
    if [ -n "$KWRITE" ]; then
        $KWRITE --file kdeglobals --group KDE --key AnimationDurationFactor "$ANIM_SPEED"
        # Simgeye tıklandığında zıplama/geri bildirim animasyonu
        $KWRITE --file klaunchrc --group FeedbackStyle --key TaskbarButton true
        $KWRITE --file klaunchrc --group FeedbackStyle --key BusyCursor true
        # KWin Pencere Açılış & Dock'tan Fırlama Animasyonları
        $KWRITE --file kwinrc --group Plugins --key blurEnabled "$BLUR_ENABLED"
        $KWRITE --file kwinrc --group Plugins --key magiclampEnabled true
        $KWRITE --file kwinrc --group Plugins --key squashEnabled false
        $KWRITE --file kwinrc --group Plugins --key scaleEnabled true
        $KWRITE --file kwinrc --group Plugins --key slidingpopupsEnabled true
        $KWRITE --file kwinrc --group Effect-blur --key BlurStrength "$BLUR_STRENGTH"
        $KWRITE --file kwinrc --group Effect-magiclamp --key AnimationDuration 220
    fi

    plasma-apply-colorscheme SpeedyOS 2>/dev/null || true
    plasma-apply-wallpaperimage "$WALLPAPER_PATH" 2>/dev/null || true

    # Köşeleri Ferah Üst Bar + Yüzen Alt Dock
    PLASMA_SCRIPT='
    panels().forEach(p => p.remove());

    var topBar = new Panel("org.kde.panel");
    topBar.location = "top";
    topBar.height = 32;
    topBar.floating = true;
    var leftPad = topBar.addWidget("org.kde.plasma.panelspacer");
    leftPad.writeConfig("expanding", false);
    leftPad.writeConfig("length", 8);
    topBar.addWidget("org.kde.plasma.kicker");
    topBar.addWidget("org.kde.plasma.appmenu");
    topBar.addWidget("org.kde.plasma.panelspacer");
    topBar.addWidget("org.kde.plasma.digitalclock");
    topBar.addWidget("org.kde.plasma.panelspacer");
    topBar.addWidget("org.kde.plasma.systemtray");
    var rightPad = topBar.addWidget("org.kde.plasma.panelspacer");
    rightPad.writeConfig("expanding", false);
    rightPad.writeConfig("length", 8);

    var dock = new Panel("org.kde.panel");
    dock.location = "bottom";
    dock.height = 56;
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
blur-background = ${BLUR_ENABLED};
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

# 5. SAĞ & SOL KENAR AKILLI PANELLERİ (SPEEDYOS EDGE HUD)
echo "🎛️ Sağ Kenar Kontrol Merkezi & Sol Kenar Sistem Monitörü Oluşturuluyor..."
cat << 'EOF' | sudo tee /usr/local/bin/speedyos-hud.py > /dev/null
#!/usr/bin/env python3
import sys, os, glob, shutil, subprocess
import tkinter as tk

MODE = sys.argv[1] if len(sys.argv) > 1 else "right"

root = tk.Tk()
root.overrideredirect(True)
root.attributes("-topmost", True)
try:
    root.attributes("-alpha", 0.94)
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

def close_win(event=None):
    root.destroy()

def check_leave(event=None):
    px, py = root.winfo_pointerxy()
    wx, wy = root.winfo_rootx(), root.winfo_rooty()
    ww, wh = root.winfo_width(), root.winfo_height()
    if not (wx - 10 <= px <= wx + ww + 10 and wy - 10 <= py <= wy + wh + 10):
        root.destroy()

root.bind("<Leave>", lambda e: root.after(450, check_leave))
root.after(12000, close_win)

header = tk.Frame(frame, bg=BG)
header.pack(fill="x", pady=(0, 10))
title_txt = "⚡ SPEEDYOS KONTROL" if MODE == "right" else "📊 SİSTEM MONİTÖRÜ"
tk.Label(header, text=title_txt, bg=BG, fg=GOLD, font=("Sans", 10, "bold")).pack(side="left")
tk.Button(header, text="✕", bg=BG, fg=MUTED, bd=0, activebackground=ACCENT,
          activeforeground="white", command=close_win, cursor="hand2").pack(side="right")

if MODE == "right":
    W, H = 290, 340
    root.geometry(f"{W}x{H}+{sw - W}+{(sh - H)//2}")

    # 1. Parlaklık
    def get_brightness():
        b_files = glob.glob("/sys/class/backlight/*/brightness")
        m_files = glob.glob("/sys/class/backlight/*/max_brightness")
        if b_files and m_files:
            try:
                cur = int(open(b_files[0]).read().strip())
                mx = int(open(m_files[0]).read().strip())
                return int((cur / mx) * 100)
            except Exception:
                pass
        return 80

    def set_brightness(val):
        pct = max(5, int(float(val)))
        b_files = glob.glob("/sys/class/backlight/*/brightness")
        m_files = glob.glob("/sys/class/backlight/*/max_brightness")
        if b_files and m_files:
            try:
                mx = int(open(m_files[0]).read().strip())
                with open(b_files[0], "w") as f:
                    f.write(str(int((pct / 100.0) * mx)))
                return
            except Exception:
                pass
        subprocess.run(["brightnessctl", "set", f"{pct}%"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    tk.Label(frame, text="☀️ Ekran Parlaklığı", bg=BG, fg=FG, font=("Sans", 9, "bold"), anchor="w").pack(fill="x")
    s_bright = tk.Scale(frame, from_=5, to=100, orient="horizontal", bg=BG, fg=FG,
                        troughcolor=CARD, activebackground=ACCENT, highlightthickness=0, command=set_brightness)
    s_bright.set(get_brightness())
    s_bright.pack(fill="x", pady=(0, 8))

    # 2. Ses & Sağ/Sol Kanal Dengesi
    vol_state = {"vol": 75, "bal": 0}
    def apply_audio(_=None):
        v = vol_state["vol"]
        b = vol_state["bal"]
        l_vol = int(v * min(1.0, (100 - b) / 100.0))
        r_vol = int(v * min(1.0, (100 + b) / 100.0))
        subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{l_vol}%", f"{r_vol}%"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def on_vol(val):
        vol_state["vol"] = int(float(val))
        apply_audio()

    def on_bal(val):
        vol_state["bal"] = int(float(val))
        apply_audio()

    tk.Label(frame, text="🔊 Ana Ses Seviyesi", bg=BG, fg=FG, font=("Sans", 9, "bold"), anchor="w").pack(fill="x")
    s_vol = tk.Scale(frame, from_=0, to=100, orient="horizontal", bg=BG, fg=FG,
                     troughcolor=CARD, activebackground=ACCENT, highlightthickness=0, command=on_vol)
    s_vol.set(75)
    s_vol.pack(fill="x", pady=(0, 8))

    tk.Label(frame, text="🎧 Ses Yönü (Sol ◀ 0 ▶ Sağ)", bg=BG, fg=FG, font=("Sans", 9, "bold"), anchor="w").pack(fill="x")
    s_bal = tk.Scale(frame, from_=-100, to=100, orient="horizontal", bg=BG, fg=GOLD,
                     troughcolor=CARD, activebackground=GOLD, highlightthickness=0, command=on_bal)
    s_bal.set(0)
    s_bal.pack(fill="x", pady=(0, 10))

    # 3. Güç & Performans Modu
    tk.Label(frame, text="⚡ Güç ve Hız Profili", bg=BG, fg=FG, font=("Sans", 9, "bold"), anchor="w").pack(fill="x", pady=(0, 4))
    p_status = tk.Label(frame, text="Aktif Mod: Seçiniz", bg=BG, fg=MUTED, font=("Sans", 8))
    p_status.pack(fill="x", pady=(0, 4))

    def set_power(mode_name, gov, pp):
        subprocess.run(["powerprofilesctl", "set", pp], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for g in glob.glob("/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"):
            try:
                open(g, "w").write(gov)
            except Exception:
                pass
        p_status.config(text=f"Aktif Mod: {mode_name}", fg=GOLD)

    btn_row = tk.Frame(frame, bg=BG)
    btn_row.pack(fill="x")
    tk.Button(btn_row, text="🌱 Tasarruf", bg=CARD, fg=FG, bd=0, padx=6, pady=5, cursor="hand2",
              command=lambda: set_power("Pil Tasarrufu", "powersave", "power-saver")).pack(side="left", expand=True, fill="x", padx=2)
    tk.Button(btn_row, text="⚖️ Dengeli", bg=CARD, fg=FG, bd=0, padx=6, pady=5, cursor="hand2",
              command=lambda: set_power("Dengeli", "schedutil", "balanced")).pack(side="left", expand=True, fill="x", padx=2)
    tk.Button(btn_row, text="🚀 Hız", bg=ACCENT, fg="white", bd=0, padx=6, pady=5, cursor="hand2",
              command=lambda: set_power("Maksimum Hız", "performance", "performance")).pack(side="left", expand=True, fill="x", padx=2)

else:
    W, H = 290, 320
    root.geometry(f"{W}x{H}+0+{(sh - H)//2}")

    ram_lbl = tk.Label(frame, text="🧠 RAM Hesaplanıyor...", bg=BG, fg=FG, font=("Sans", 9, "bold"), anchor="w")
    ram_lbl.pack(fill="x")
    ram_bar = tk.Canvas(frame, height=12, bg=CARD, highlightthickness=0)
    ram_bar.pack(fill="x", pady=(3, 10))

    disk_lbl = tk.Label(frame, text="💾 Disk Hesaplanıyor...", bg=BG, fg=FG, font=("Sans", 9, "bold"), anchor="w")
    disk_lbl.pack(fill="x")
    disk_bar = tk.Canvas(frame, height=12, bg=CARD, highlightthickness=0)
    disk_bar.pack(fill="x", pady=(3, 10))

    cpu_lbl = tk.Label(frame, text="🔥 CPU & Güç Modu...", bg=BG, fg=FG, font=("Sans", 9, "bold"), anchor="w")
    cpu_lbl.pack(fill="x", pady=(0, 6))

    swap_lbl = tk.Label(frame, text="⚡ zRAM & Önbellek...", bg=BG, fg=MUTED, font=("Sans", 8), anchor="w")
    swap_lbl.pack(fill="x", pady=(0, 10))

    def clean_ram():
        subprocess.run(["sync"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            open("/proc/sys/vm/drop_caches", "w").write("3")
        except Exception:
            pass
        update_stats()

    tk.Button(frame, text="🧹 RAM Önbelleğini Hemen Rahatlat", bg=ACCENT, fg="white", bd=0,
              pady=6, font=("Sans", 8, "bold"), cursor="hand2", command=clean_ram).pack(fill="x")

    def update_stats():
        if not root.winfo_exists():
            return
        # RAM
        mem = {}
        with open("/proc/meminfo") as f:
            for line in f:
                parts = line.split()
                if len(parts) >= 2:
                    mem[parts[0].rstrip(":")] = int(parts[1])
        tot_gb = mem.get("MemTotal", 1) / 1048576.0
        avail_gb = mem.get("MemAvailable", 0) / 1048576.0
        used_gb = max(0.0, tot_gb - avail_gb)
        ram_pct = min(100, int((used_gb / tot_gb) * 100))
        ram_lbl.config(text=f"🧠 RAM: {used_gb:.2f} / {tot_gb:.2f} GB (%{ram_pct})")
        ram_bar.delete("all")
        ram_bar.create_rectangle(0, 0, int((W - 36) * (ram_pct / 100.0)), 12, fill=ACCENT, width=0)

        # Disk
        du = shutil.disk_usage("/")
        d_tot = du.total / (1024**3)
        d_used = du.used / (1024**3)
        d_pct = min(100, int((du.used / du.total) * 100))
        disk_lbl.config(text=f"💾 Disk: {d_used:.1f} / {d_tot:.1f} GB (%{d_pct})")
        disk_bar.delete("all")
        disk_bar.create_rectangle(0, 0, int((W - 36) * (d_pct / 100.0)), 12, fill=GOLD, width=0)

        # CPU & Governor
        load1 = os.getloadavg()[0]
        govs = glob.glob("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor")
        gov = open(govs[0]).read().strip() if govs else "aktif"
        cpu_lbl.config(text=f"🔥 CPU Yükü: {load1:.2f}  |  Mod: {gov}")

        # Swap / zRAM
        swaps = open("/proc/swaps").read().splitlines()[1:]
        swap_lbl.config(text=f"⚡ Aktif Sanal Bellek / zRAM: {len(swaps)} Katman Devrede")
        root.after(1000, update_stats)

    update_stats()

root.mainloop()
EOF
sudo chmod +x /usr/local/bin/speedyos-hud.py

# 6. RAM, AĞ (TCP BBR), zRAM, KALICI HDD VE DISK ÖNBELLEK MODÜLÜ
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
    echo "🧹 Düşük RAM Koruması: Dosya indeksleyici (Baloo) kapatılıyor..."
    balooctl6 disable 2>/dev/null || balooctl disable 2>/dev/null || true

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
    sync && sudo sysctl -w vm.drop_caches=3 > /dev/null 2>&1
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

# 7. SPEEDYWALL (0 MB RAM GÜVENLİK DUVARI) & SPEEDYSECURE (HAFİF ANTİVİRÜS)
echo "🛡️ SpeedyWall ve SpeedySecure Güvenlik Katmanı Kuruluyor..."
install_pkg ufw clamav clamav-update rkhunter

sudo systemctl disable --now firewalld 2>/dev/null || true
sudo systemctl disable --now clamav-daemon clamav-freshclam clamd@scan 2>/dev/null || true

sudo ufw default deny incoming >/dev/null 2>&1 || true
sudo ufw default allow outgoing >/dev/null 2>&1 || true
sudo ufw --force enable >/dev/null 2>&1 || true

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

# 8. AKILLI ARKA PLAN MOTORU (OYUN DONDURUCU + DOCK GENİŞLETİCİ + KENAR TETİKLEYİCİ)
cat << 'EOF' | sudo tee /usr/local/bin/speedyos-daemon > /dev/null
#!/bin/bash
EXCLUDE_LIST="Xorg|Xwayland|systemd|dbus|pipewire|pulseaudio|wireplumber|bash|xdotool|xprop|plank|plasmashell|kwin|picom|python3|speedyos"
IS_FROZEN=0
DOCK_MODE="fit"
SCREEN_W=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ {print $2}' | cut -d'x' -f1)
[ -z "$SCREEN_W" ] && SCREEN_W=1366

while true; do
    ACTIVE_WIN=$(xdotool getactivewindow 2>/dev/null)
    ACTIVE_PID=$(xdotool getwindowpid "$ACTIVE_WIN" 2>/dev/null)
    WM_STATE=$(xprop -id "$ACTIVE_WIN" _NET_WM_STATE 2>/dev/null)

    # 1. Tam ekran oyunda arka planı dondur
    if echo "$WM_STATE" | grep -qi "FULLSCREEN" && [ -n "$ACTIVE_PID" ]; then
        if [ "$IS_FROZEN" -eq 0 ]; then
            for pid in $(ps -u "$USER" -o pid,comm | grep -vE "$EXCLUDE_LIST" | awk '{print $1}'); do
                [ "$pid" != "$ACTIVE_PID" ] && [ "$pid" != "$$" ] && kill -STOP "$pid" 2>/dev/null
            done
            IS_FROZEN=1
        fi
    elif [ "$IS_FROZEN" -eq 1 ]; then
        for pid in $(ps -u "$USER" -o pid,comm | grep -vE "$EXCLUDE_LIST" | awk '{print $1}'); do
            kill -CONT "$pid" 2>/dev/null
        done
        IS_FROZEN=0
    fi

    # 2. Pencere büyütüldüğünde alt dock'u tam genişlet, küçülünce yüzen kapsüle döndür
    if pgrep -x "plasmashell" > /dev/null; then
        if echo "$WM_STATE" | grep -qi "MAXIMIZED"; then
            if [ "$DOCK_MODE" != "fill" ]; then
                busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s \
                "panels().forEach(p => { if (p.location == 'bottom') { try { p.lengthMode = 'fill'; } catch(e) {} } });" >/dev/null 2>&1 || true
                DOCK_MODE="fill"
            fi
        else
            if [ "$DOCK_MODE" != "fit" ]; then
                busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s \
                "panels().forEach(p => { if (p.location == 'bottom') { try { p.lengthMode = 'fit'; } catch(e) {} } });" >/dev/null 2>&1 || true
                DOCK_MODE="fit"
            fi
        fi
    fi

    # 3. Fare Sağ veya Sol Ekran Kenarına Değerse Akıllı Paneli Aç
    eval $(xdotool getmouselocation --shell 2>/dev/null)
    if [ -n "$X" ]; then
        if [ "$X" -ge $((SCREEN_W - 2)) ]; then
            pgrep -f "speedyos-hud.py right" >/dev/null || nohup python3 /usr/local/bin/speedyos-hud.py right >/dev/null 2>&1 &
        elif [ "$X" -le 2 ]; then
            pgrep -f "speedyos-hud.py left" >/dev/null || nohup python3 /usr/local/bin/speedyos-hud.py left >/dev/null 2>&1 &
        fi
    fi

    sleep 0.5
done
EOF
sudo chmod +x /usr/local/bin/speedyos-daemon

# Otomatik Başlatma Kaydı (Bilgisayar her açıldığında devreye girsin)
mkdir -p ~/.config/autostart/
cat << 'EOF' > ~/.config/autostart/speedyos-daemon.desktop
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/speedyos-daemon
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=SpeedyOS Arka Plan Motoru
EOF

pkill -f "speedyos-daemon" 2>/dev/null || true
nohup /usr/local/bin/speedyos-daemon >/dev/null 2>&1 &

echo "🎉 SpeedyOS - Evrensel Linux Arayüzü (Tam Sürüm) Başarıyla Kuruldu!"
