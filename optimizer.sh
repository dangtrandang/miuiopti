#!/system/bin/sh
MODDIR="${0%/*}"
LOGFILE="$MODDIR/optimizer.log"
APP_RECORD="$MODDIR/optimized_apps.txt"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$LOGFILE"
    echo "$1"
}

scan_debloat() {
    log "--> Đang quét bloatware Xiaomi..."
    local bloat_pkgs="
com.miui.analytics
com.miui.daemon
com.miui.yellowpage
com.miui.hybrid
com.miui.hybrid.accessory
com.xiaomi.discover
com.miui.bugreport
com.xiaomi.joyose
"
    local count=0
    for pkg in $bloat_pkgs; do
        if pm list packages "$pkg" | grep -q "^package:$pkg$"; then
            if ! pm list packages -d "$pkg" | grep -q "^package:$pkg$"; then
                pm disable-user --user 0 "$pkg" >/dev/null 2>&1
                log "  [Đã tắt] $pkg"
                count=$((count + 1))
            fi
        fi
    done
    if [ "$count" -eq 0 ]; then
        log "  [OK] Không có dịch vụ rác nào đang hoạt động."
    else
        log "  [OK] Đã tắt $count dịch vụ rác."
    fi
}

apply_kernel() {
    log "--> Đang tối ưu Kernel & UFS..."
    if grep -q "bbr" /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
        echo bbr > /proc/sys/net/ipv4/tcp_congestion_control
        log "  [OK] TCP Congestion: bbr"
    fi

    if [ -f /proc/sys/vm/vfs_cache_pressure ]; then
        echo 80 > /proc/sys/vm/vfs_cache_pressure
        log "  [OK] VFS Cache Pressure: 80"
    fi

    local ufs_count=0
    for b in /sys/block/sd*/queue/read_ahead_kb; do
        if [ -f "$b" ]; then
            echo 512 > "$b"
            ufs_count=$((ufs_count + 1))
        fi
    done
    for b in /sys/block/sd*/queue/rq_affinity; do
        [ -f "$b" ] && echo 2 > "$b"
    done
    for b in /sys/block/sd*/queue/add_random; do
        [ -f "$b" ] && echo 0 > "$b"
    done
    for b in /sys/block/sd*/queue/iostats; do
        [ -f "$b" ] && echo 0 > "$b"
    done
    log "  [OK] UFS 3.1: Đã tăng bộ đệm 512KB trên $ufs_count phân vùng."
}

smart_dexopt() {
    log "--> Đang quét ứng dụng cần tối ưu (Smart DEX)..."
    [ ! -f "$APP_RECORD" ] && touch "$APP_RECORD"

    local user_apps=$(pm list packages -3 | sed 's/^package://')
    local new_count=0

    for app in $user_apps; do
        if ! grep -q "^$app$" "$APP_RECORD" 2>/dev/null; then
            log "  [Biên dịch] $app..."
            cmd package compile -m speed-profile "$app" >/dev/null 2>&1
            echo "$app" >> "$APP_RECORD"
            new_count=$((new_count + 1))
        fi
    done

    if [ "$new_count" -gt 0 ]; then
        log "  [OK] Đã biên dịch xong $new_count ứng dụng mới."
    else
        log "  [OK] Tất cả ứng dụng đã được tối ưu từ trước."
    fi
}

case "$1" in
    boot)
        echo "=== BẮT ĐẦU TỰ ĐỘNG NẠP LÚC KHỞI ĐỘNG ===" >> "$LOGFILE"
        scan_debloat
        apply_kernel
        if [ ! -f "$APP_RECORD" ]; then
            pm list packages -3 | sed 's/^package://' > "$APP_RECORD"
        fi
        log "=== NẠP THÀNH CÔNG (Tự động thoát, không tốn tài nguyên) ==="
        ;;
    scan|manual)
        scan_debloat
        apply_kernel
        smart_dexopt
        echo 3 > /proc/sys/vm/drop_caches
        log "--> Đã dọn bộ đệm RAM."
        ;;
    *)
        scan_debloat
        apply_kernel
        smart_dexopt
        ;;
esac