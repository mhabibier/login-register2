#!/bin/bash
# =============================================================
# Snort IDS Entrypoint — ArgonAuth Kamsis
# Auto-detect network interface Docker
# =============================================================

echo "============================================"
echo "     ArgonAuth — Snort IDS Container"
echo "     NIM: 101032300005"
echo "============================================"

# ============================================================
# AUTO-UPDATE COMMUNITY RULES (Emerging Threats Open Ruleset)
# Dijalankan SEKALI saat container pertama kali start.
# Untuk manual update: docker exec argonauth_snort_101032300005 /usr/local/bin/update_rules.sh
# ============================================================
auto_update_community_rules() {
    local ET_OUTPUT="/etc/snort/rules/emerging-threats.rules"
    local META_FILE="/etc/snort/rules/.community_rules_meta"
    local ET_BASE="https://rules.emergingthreats.net/open/snort-2.9.0/rules"
    local TIMESTAMP
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    echo ""
    echo "[INFO] === Auto-Update Community Rules ==="

    # Cek apakah sudah pernah update sebelumnya
    if [ -f "${META_FILE}" ]; then
        LAST_UPDATE=$(grep 'last_update=' "${META_FILE}" | cut -d'=' -f2)
        TOTAL=$(grep 'total_rules=' "${META_FILE}" | cut -d'=' -f2)
        echo "[INFO] Rules komunitas sudah ada (update terakhir: ${LAST_UPDATE}, ${TOTAL} rules)"
        echo "[INFO] Lewati auto-update. Gunakan update_rules.sh untuk update manual."
        echo ""
        return 0
    fi

    echo "[INFO] Pertama kali start — download Emerging Threats Community Rules..."

    # Rule files yang didownload (relevan untuk web app security)
    local ET_RULES=(
        "emerging-web-server.rules"
        "emerging-dos.rules"
        "emerging-scan.rules"
        "emerging-sql.rules"
    )

    # Tulis header ke output
    cat > "${ET_OUTPUT}" << HEADER
# =============================================================
# emerging-threats.rules — Emerging Threats Open Ruleset
# ArgonAuth Kamsis | NIM: 101032300005
# Auto-downloaded: ${TIMESTAMP}
# Sumber: https://rules.emergingthreats.net/open/snort-2.9.0/rules/
# =============================================================
HEADER

    local TOTAL_RULES=0 FAILED=0 SUCCESS=0

    for RULE_FILE in "${ET_RULES[@]}"; do
        URL="${ET_BASE}/${RULE_FILE}"
        TEMP="/tmp/${RULE_FILE}"
        printf "[INFO]   Downloading %-35s ... " "${RULE_FILE}"

        if curl -sS --max-time 20 --retry 2 -o "${TEMP}" "${URL}" 2>/dev/null; then
            # Validasi: file tidak boleh berisi HTML (artinya server return error page)
            if grep -qi "<html" "${TEMP}" 2>/dev/null; then
                printf "INVALID (server returned HTML, bukan rules)\n"
                rm -f "${TEMP}"
                FAILED=$((FAILED + 1))
            else
                COUNT=$(grep -cE "^(alert|drop|reject|pass)" "${TEMP}" 2>/dev/null || echo 0)
                printf "OK (%d rules)\n" "${COUNT}"
                {
                    echo ""
                    echo "# ---- ${RULE_FILE} (Downloaded: ${TIMESTAMP}) ----"
                    cat "${TEMP}"
                } >> "${ET_OUTPUT}"
                TOTAL_RULES=$((TOTAL_RULES + COUNT))
                SUCCESS=$((SUCCESS + 1))
                rm -f "${TEMP}"
            fi
        else
            printf "GAGAL (tidak ada internet?)\n"
            FAILED=$((FAILED + 1))
        fi
    done

    # Simpan metadata
    {
        echo "last_update=${TIMESTAMP}"
        echo "total_rules=${TOTAL_RULES}"
        echo "success=${SUCCESS}"
        echo "failed=${FAILED}"
    } > "${META_FILE}"

    echo ""
    echo "[INFO] Community rules: ${TOTAL_RULES} rules dari ${SUCCESS}/${#ET_RULES[@]} file"
    if [ "${FAILED}" -gt 0 ]; then
        echo "[WARN] ${FAILED} file gagal didownload (container tetap jalan dengan rule lokal)"
    fi
    echo "[INFO] === Auto-Update Selesai ==="
    echo ""
}

# Pastikan file emerging-threats.rules selalu ada (placeholder jika belum didownload)
# Jika file ada tapi berisi HTML (curl error page), hapus dan buat ulang sebagai placeholder
if [ ! -f /etc/snort/rules/emerging-threats.rules ]; then
    echo "[INFO] Membuat placeholder emerging-threats.rules..."
    echo "# Placeholder — akan diisi oleh auto-update saat startup" > /etc/snort/rules/emerging-threats.rules
elif grep -qi "<html" /etc/snort/rules/emerging-threats.rules 2>/dev/null; then
    echo "[WARN] emerging-threats.rules berisi HTML (download sebelumnya gagal) — reset ke placeholder"
    echo "# Placeholder — download gagal, akan dicoba ulang" > /etc/snort/rules/emerging-threats.rules
    # Hapus metadata agar auto-update berjalan ulang
    rm -f /etc/snort/rules/.community_rules_meta
fi

# Jalankan auto-update
auto_update_community_rules

# ============================================================
# AUTO-DETECT INTERFACE — PERBAIKAN UTAMA
# ============================================================
# Pada network_mode: host, Snort melihat semua interface host (termasuk Docker bridges).
# Kita perlu menemukan interface bridge Docker yang membawa traffic frontend_net (172.20.x.x).
#
# Format output `ip route`:
#   172.20.0.0/24 dev br-abc123 proto kernel scope link src 172.20.0.1
# Interface ada setelah keyword "dev"
# ============================================================

echo ""
echo "[INFO] === Deteksi Interface ==="
echo "[INFO] Semua routes:"
ip route
echo ""

# Metode 1: Cari interface untuk subnet frontend (172.20.x.x)
IFACE=$(ip route | grep "172\.20\." | grep -oP 'dev \K\S+' | head -1)
echo "[INFO] Metode 1 (frontend 172.20.x): IFACE=$IFACE"

if [ -z "$IFACE" ]; then
    # Metode 2: Cari interface untuk subnet backend (172.21.x.x)
    IFACE=$(ip route | grep "172\.21\." | grep -oP 'dev \K\S+' | head -1)
    echo "[INFO] Metode 2 (backend 172.21.x): IFACE=$IFACE"
fi

if [ -z "$IFACE" ]; then
    # Metode 3: Cari semua Docker bridge interfaces (br-xxxxx)
    IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep '^br-' | head -1)
    echo "[INFO] Metode 3 (any br- interface): IFACE=$IFACE"
fi

if [ -z "$IFACE" ]; then
    # Metode 4: Cari docker0
    IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep '^docker0$' | head -1)
    echo "[INFO] Metode 4 (docker0): IFACE=$IFACE"
fi

if [ -z "$IFACE" ]; then
    # Metode 5 (fallback terakhir): interface pertama bukan loopback
    IFACE=$(ip -o link show up | awk -F': ' '{print $2}' | grep -vE '^lo$' | head -1)
    echo "[INFO] Metode 5 (fallback first non-lo): IFACE=$IFACE"
fi

# Validasi interface benar-benar ada dan UP
if [ -z "$IFACE" ]; then
    echo "[ERROR] Tidak bisa menemukan interface jaringan!"
    echo "[ERROR] Daftar semua interface:"
    ip -o link show
    exit 1
fi

# Pastikan interface UP
ip link set "$IFACE" up 2>/dev/null || true

echo ""
echo "[INFO] ✅ Interface terpilih: $IFACE"
echo "[INFO] Detail interface:"
ip addr show "$IFACE" 2>/dev/null || true
echo ""
echo "[INFO] Routes terkait Docker:"
ip route | grep -E "172\.(20|21)\." || echo "[WARN] Tidak ada route 172.20.x/172.21.x"
echo ""
echo "[INFO] Semua interface yang tersedia:"
ip -o link show | awk -F': ' '{print "  - "$2}'


# ---- Pastikan log directory dan file ada ----
mkdir -p /var/log/snort
touch /var/log/snort/alert
# Beri permission write ke semua user (agar snort user bisa menulis)
chmod 777 /var/log/snort
chmod 666 /var/log/snort/alert
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
echo "[INFO] ============================================"
echo "[INFO] Memvalidasi konfigurasi Snort..."
echo "[INFO] ============================================"
VALIDATION_OUTPUT=$(snort -T -c /etc/snort/snort.conf -i "$IFACE" 2>&1)
VALIDATION_EXIT=$?

# Tampilkan output penting dari validasi
echo "$VALIDATION_OUTPUT" | grep -E "(Snort|Rule|ERROR|WARNING|Successfully|FATAL|fatal)" || true

if [ $VALIDATION_EXIT -ne 0 ]; then
    echo ""
    echo "[ERROR] ❌ Validasi Snort GAGAL (exit code: $VALIDATION_EXIT)"
    echo "[ERROR] Full output:"
    echo "$VALIDATION_OUTPUT" | tail -30
    echo ""
    echo "[WARN] Mencoba jalankan Snort tanpa preprocessor yang bermasalah..."
fi

echo ""
echo "[INFO] ============================================"
echo "[INFO] Menjalankan Snort di interface: $IFACE"
echo "[INFO] Log alerts : /var/log/snort/alert"
echo "[INFO] Mode       : IDS pasif (tanpa -Q)"
echo "[INFO] Alert format: fast (-A fast)"
echo "[INFO] ============================================"

# ---- Jalankan Snort + Live Alert Monitor ----
# CATATAN:
#   -A fast  : format alert satu baris (mudah dibaca)
#   -k none  : abaikan checksum error (umum di Docker)
#   TANPA -Q : Mode IDS pasif (bukan IPS inline) — cocok untuk monitoring
#
# ARSITEKTUR:
#   Snort     → background (menulis alert ke /var/log/snort/alert)
#   tail -F   → foreground (membaca alert dan tampilkan di docker logs)
#   trap      → kalau container di-stop, kill Snort juga
# ============================================================

# Jalankan Snort di background
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

# Tunggu sebentar agar Snort sempat start dan buat file alert
sleep 3

# Cek apakah Snort masih hidup
if ! kill -0 $SNORT_PID 2>/dev/null; then
    echo "[ERROR] ❌ Snort gagal start! Cek konfigurasi."
    echo "[ERROR] Menjalankan ulang dengan output verbose..."
    snort -A fast -c /etc/snort/snort.conf -i "$IFACE" -l /var/log/snort -k none 2>&1
    exit 1
fi

echo "[INFO] ✅ Snort berhasil start!"
echo "[INFO] File alert:"
ls -la /var/log/snort/alert* 2>/dev/null || echo "[WARN] Belum ada file alert"
echo ""
echo "[INFO] ============================================"
echo "[INFO] 🔴 LIVE ALERT MONITOR — Menunggu alert..."
echo "[INFO] ============================================"

# Trap: kalau container di-stop (SIGTERM/SIGINT), kill Snort juga
trap "echo '[INFO] Stopping Snort...'; kill $SNORT_PID 2>/dev/null; exit 0" SIGTERM SIGINT

# Jalankan tail -F di FOREGROUND (ini yang menjaga container hidup)
# dan juga memonitor apakah Snort masih jalan
while kill -0 $SNORT_PID 2>/dev/null; do
    tail -F /var/log/snort/alert 2>/dev/null &
    TAIL_PID=$!
    # Cek setiap 5 detik apakah Snort masih hidup
    wait $SNORT_PID 2>/dev/null
    SNORT_EXIT=$?
    kill $TAIL_PID 2>/dev/null
    echo "[WARN] Snort berhenti dengan exit code: $SNORT_EXIT"
    break
done

exit ${SNORT_EXIT:-1}

