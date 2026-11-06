#!/system/bin/sh
MODDIR="${0%/*}"
LOGFILE="$MODDIR/optimizer.log"
APP_RECORD="$MODDIR/optimized_apps.txt"
LOCKFILE="$MODDIR/.dex_lock"

DEVICE_MODEL=$(getprop ro.product.model)
DEVICE_CODENAME=$(getprop ro.product.device)
[ -z "$DEVICE_MODEL" ] && DEVICE_MODEL="Xiaomi Device"
[ -z "$DEVICE_CODENAME" ] && DEVICE_CODENAME="Generic"

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
    log "--> Đang tối ưu Kernel, I/O UFS & RAM..."

    # 1. TCP Congestion & TCP Fast Open
    if grep -q "bbr" /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
        echo bbr > /proc/sys/net/ipv4/tcp_congestion_control
        log "  [OK] TCP Congestion: bbr"
    fi
    if [ -f /proc/sys/net/ipv4/tcp_fastopen ]; then
        echo 3 > /proc/sys/net/ipv4/tcp_fastopen
        log "  [OK] TCP Fast Open: 3 (client + server)"
    fi

    # 2. VFS Cache Pressure & Swappiness
    if [ -f /proc/sys/vm/vfs_cache_pressure ]; then
        echo 80 > /proc/sys/vm/vfs_cache_pressure
        log "  [OK] VFS Cache Pressure: 80"
    fi
    if [ -f /proc/sys/vm/swappiness ]; then
        echo 60 > /proc/sys/vm/swappiness
        log "  [OK] Swappiness: 60 (giảm áp lực ZRAM, giữ app mượt)"
    fi

    # 3. Disable background tracing (traced, traced_probes)
    setprop persist.traced.enable 0
    stop traced 2>/dev/null
    stop traced_probes 2>/dev/null

    # 4. UFS tuning: read_ahead_kb, scheduler noop, etc.
    local ufs_count=0
    for b in /sys/block/sd*/queue/read_ahead_kb; do
        if [ -f "$b" ]; then
            echo 512 > "$b"
            ufs_count=$((ufs_count + 1))
        fi
    done

    # Switch I/O scheduler to noop for flash storage
    local sched_changed=0
    for s in /sys/block/sd*/queue/scheduler; do
        if [ -f "$s" ] && grep -q "noop" "$s"; then
            echo noop > "$s"
            sched_changed=1
        fi
    done
    if [ "$sched_changed" -eq 1 ]; then
        log "  [OK] I/O Scheduler: noop (tối ưu chip flash UFS)"
    fi

    for b in /sys/block/sd*/queue/rq_affinity; do
        [ -f "$b" ] && echo 2 > "$b"
    done
    for b in /sys/block/sd*/queue/add_random; do
        [ -f "$b" ] && echo 0 > "$b"
    done
    for b in /sys/block/sd*/queue/iostats; do
        [ -f "$b" ] && echo 0 > "$b"
    done
    log "  [OK] UFS Storage: Đã tăng bộ đệm 512KB trên $ufs_count phân vùng."
}

smart_dexopt() {
    log "--> Đang quét ứng dụng cần tối ưu (Smart DEX)..."
    [ ! -f "$APP_RECORD" ] && touch "$APP_RECORD"

    local user_apps=$(pm list packages -3 | sed 's/^package://')
    local pending_apps=""
    local new_count=0

    for app in $user_apps; do
        if ! grep -q "^$app$" "$APP_RECORD" 2>/dev/null; then
            pending_apps="$pending_apps $app"
            new_count=$((new_count + 1))
        fi
    done

    if [ "$new_count" -eq 0 ]; then
        log "  [OK] Tất cả ứng dụng đã được tối ưu từ trước."
    elif [ "$new_count" -le 2 ]; then
        # 1-2 app mới: Biên dịch trực tiếp trong giao diện (rất nhanh, 5-10s)
        for app in $pending_apps; do
            log "  [Biên dịch] $app..."
            cmd package compile -m speed-profile "$app" >/dev/null 2>&1
            echo "$app" >> "$APP_RECORD"
        done
        log "  [OK] Đã biên dịch xong $new_count ứng dụng mới."
    else
        # Khi có nhiều hơn 2 app (lần đầu flash hoặc phục hồi nhiều app):
        # Đẩy chạy ngầm bằng nohup để Action phản hồi tức thì trong 1 giây, không treo giao diện
        if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE" 2>/dev/null)" 2>/dev/null; then
            log "  [Đang chạy] Quá trình biên dịch nền trước đó vẫn đang tiến hành."
        else
            log "  [Phát hiện] $new_count ứng dụng cần tối ưu."
            log "  [Chạy ngầm] Đang tối ưu trong nền (không làm đơ máy, có thể tắt cửa sổ)."
            nohup sh -c '
                echo $$ > "'"$LOCKFILE"'"
                for a in '"$pending_apps"'; do
                    cmd package compile -m speed-profile "$a" >/dev/null 2>&1
                    echo "$a" >> "'"$APP_RECORD"'"
                done
                rm -f "'"$LOCKFILE"'"
                echo "[$(date "+%Y-%m-%d %H:%M:%S")] [Hoàn tất] Đã biên dịch ngầm xong '"$new_count"' ứng dụng." >> "'"$LOGFILE"'"
            ' >/dev/null 2>&1 &
        fi
    fi
}

case "$1" in
    boot)
        echo "=== BẮT ĐẦU TỰ ĐỘNG NẠP LÚC KHỞI ĐỘNG ($DEVICE_MODEL - $DEVICE_CODENAME) ===" >> "$LOGFILE"
        scan_debloat
        apply_kernel
        if [ ! -f "$APP_RECORD" ] || [ ! -s "$APP_RECORD" ]; then
            local pkgs=$(pm list packages -3 | sed 's/^package://')
            [ -n "$pkgs" ] && echo "$pkgs" > "$APP_RECORD"
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
