#!/system/bin/sh
MODDIR="${0%/*}"

DEVICE_MODEL=$(getprop ro.product.model)
DEVICE_CODENAME=$(getprop ro.product.device)
[ -z "$DEVICE_MODEL" ] && DEVICE_MODEL="Xiaomi Device"
[ -z "$DEVICE_CODENAME" ] && DEVICE_CODENAME="Generic"

echo "======================================"
echo "    OPTIMIZER: $DEVICE_MODEL ($DEVICE_CODENAME)"
echo "======================================"
echo ""
sh "$MODDIR/optimizer.sh" manual
echo ""
echo "======================================"
echo " [OK] QUÉT & TỐI ƯU HOÀN TẤT!"
echo " Đang giữ màn hình 10 giây để xem log..."
echo "======================================"
sleep 10
