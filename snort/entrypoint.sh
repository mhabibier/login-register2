#!/bin/bash
# =============================================================
# Snort IDS Entrypoint — ArgonAuth DevSecOps
# Auto-detect network interface Docker
# =============================================================

echo "============================================"
echo "     ArgonAuth — Snort IDS Container"
echo "============================================"

# ---- Auto-detect interface ----
# Cari interface yang punya subnet Docker kita (172.20.x.x atau 172.21.x.x)
IFACE=$(ip route | grep -E "172\.(20|21)\." | awk '{print $3}' | head -1)

if [ -z "$IFACE" ]; then
    # Fallback: interface pertama selain loopback
    IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1)
fi

if [ -z "$IFACE" ]; then
    IFACE="eth0"
fi

echo "[INFO] Interface terdeteksi : $IFACE"
echo "[INFO] Daftar interface     :"
ip -o link show | awk -F': ' '{print "  - "$2}'

# ---- Pastikan log directory dan file ada ----
mkdir -p /var/log/snort
touch /var/log/snort/snort.alert.fast
chown -R snort:snort /var/log/snort 2>/dev/null || true

# ---- Verifikasi unicode.map tersedia ----
# File ini dibutuhkan oleh preprocessor http_inspect
if [ -f /etc/snort/unicode.map ]; then
    echo "[INFO] unicode.map ditemukan di /etc/snort/unicode.map"
else
    echo "[WARN] unicode.map tidak ditemukan — http_inspect mungkin gagal"
fi

# ---- Test konfigurasi Snort ----
echo ""
echo "[INFO] Memvalidasi konfigurasi Snort..."
snort -T -c /etc/snort/snort.conf -i "$IFACE" 2>&1 | grep -E "(Snort|Rule|ERROR|WARNING|Successfully)" || true

echo ""
echo "[INFO] Menjalankan Snort di interface: $IFACE"
echo "[INFO] Log alerts : /var/log/snort/snort.alert.fast"
echo "============================================"

# ---- Jalankan Snort sebagai background process (IDS / passive mode) ----
# CATATAN:
#   -A fast  : format alert satu baris (mudah dibaca)
#   -k none  : abaikan checksum error (umum di Docker)
#   TANPA -Q : Mode IDS pasif (bukan IPS inline) — cocok untuk monitoring
snort \
    -A fast \
    -c /etc/snort/snort.conf \
    -i "$IFACE" \
    -l /var/log/snort \
    -u snort \
    -g snort \
    -k none 2>&1 &

SNORT_PID=$!
echo "[INFO] Snort berjalan dengan PID: $SNORT_PID"

# ---- Tail alert log agar terlihat di docker logs ----
echo "[INFO] Menampilkan live alerts (tail -F)..."
tail -F /var/log/snort/snort.alert.fast 2>/dev/null &

# ---- Tunggu proses snort selesai (jaga container tetap hidup) ----
wait $SNORT_PID
EXIT_CODE=$?
echo "[WARN] Snort berhenti dengan exit code: $EXIT_CODE"
exit $EXIT_CODE

