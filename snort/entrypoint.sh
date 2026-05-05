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
                COUNT=$(grep -cE "^(alert|drop|reject|pass)" "${TEMP}" 2>/dev/null || true)
                COUNT=$((COUNT + 0))
                printf "OK (%d rules)\n" "$COUNT"
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

    # Append ICMP rules ke community rules
    cat >> "${ET_OUTPUT}" << 'ICMP_RULES'

# ================================================================
# ICMP Detection (Custom Addition)
# ================================================================
alert icmp any any -> $HOME_NET any (msg:"[ET-Custom] ICMP Ping Detected"; itype:8; classtype:misc-activity; priority:1; sid:9901001; rev:1;)
alert icmp any any -> $HOME_NET any (msg:"[ET-Custom] ICMP Flood Detected"; itype:8; detection_filter:track by_src, count 10, seconds 5; classtype:attempted-dos; priority:1; sid:9901002; rev:1;)
ICMP_RULES
    TOTAL_RULES=$((TOTAL_RULES + 2))
    echo "[INFO] ICMP rules (priority 1) ditambahkan ke community rules"

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
# AUTO-DETECT INTERFACE — PERBAIKAN UTAMA v2
# ============================================================
# Pada network_mode: host, Snort melihat semua interface host termasuk:
#   - Docker bridges (br-xxxx) ← yang kita mau
#   - VMware interfaces (ens33) ← JANGAN dipilih!
#   - docker0
#
# PENTING: Harus eksplisit pilih br-* (Docker bridge) untuk menghindari
# konflik dengan interface host lainnya
# ============================================================

echo ""
echo "[INFO] === Deteksi Interface ==="
echo "[INFO] Semua routes:"
ip route
echo ""

# Metode 1: Cari DOCKER BRIDGE (br-*) untuk subnet frontend (192.168.10.x)
# Pola: grep khusus br-* agar tidak memilih ens33/VMware
IFACE=$(ip route | grep "192\.168\.10\." | grep -oP 'dev \Kbr-\S+' | head -1)
echo "[INFO] Metode 1 (Docker bridge frontend 192.168.10.x): IFACE=$IFACE"

if [ -z "$IFACE" ]; then
    # Metode 2: Cari DOCKER BRIDGE (br-*) untuk subnet backend (192.168.20.x)
    IFACE=$(ip route | grep "192\.168\.20\." | grep -oP 'dev \Kbr-\S+' | head -1)
    echo "[INFO] Metode 2 (Docker bridge backend 192.168.20.x): IFACE=$IFACE"
fi

if [ -z "$IFACE" ]; then
    # Metode 3: Cari interface APAPUN (termasuk non-bridge) untuk 192.168.10.x
    # Fallback jika Docker pakai nama interface non-standar
    IFACE=$(ip route | grep "192\.168\.10\." | grep -oP 'dev \K\S+' | head -1)
    echo "[INFO] Metode 3 (any interface frontend 192.168.10.x): IFACE=$IFACE"
fi

if [ -z "$IFACE" ]; then
    # Metode 4: Cari semua Docker bridge interfaces (br-xxxxx)
    IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep '^br-' | head -1)
    echo "[INFO] Metode 4 (any br- interface): IFACE=$IFACE"
fi

if [ -z "$IFACE" ]; then
    # Metode 5: Cari docker0
    IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep '^docker0$' | head -1)
    echo "[INFO] Metode 5 (docker0): IFACE=$IFACE"
fi

if [ -z "$IFACE" ]; then
    # Metode 6 (fallback terakhir): interface pertama bukan loopback
    IFACE=$(ip -o link show up | awk -F': ' '{print $2}' | grep -vE '^lo$' | head -1)
    echo "[INFO] Metode 6 (fallback first non-lo): IFACE=$IFACE"
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
ip route | grep -E "192\.168\.(10|20)\." || echo "[WARN] Tidak ada route 192.168.10.x/192.168.20.x"
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
#   TANPA -Q : Mode IDS pasif (bukan IPS inline)
#   TANPA -u/-g : Jalankan sebagai root agar pasti bisa tulis ke alert file
# ============================================================

# Kosongkan alert file lama agar monitoring bersih
> /var/log/snort/alert

# Jalankan Snort di background (sebagai root untuk hindari permission issue)
snort \
    -A fast \
    -c /etc/snort/snort.conf \
    -i "$IFACE" \
    -l /var/log/snort \
    -k none 2>&1 &

SNORT_PID=$!
echo "[INFO] Snort berjalan dengan PID: $SNORT_PID"

# Tunggu agar Snort sempat inisialisasi
sleep 5

# Cek apakah Snort masih hidup
if ! kill -0 $SNORT_PID 2>/dev/null; then
    echo "[ERROR] ❌ Snort gagal start! Menampilkan error..."
    snort -A fast -c /etc/snort/snort.conf -i "$IFACE" -l /var/log/snort -k none 2>&1
    exit 1
fi

echo "[INFO] ✅ Snort berhasil start dan berjalan!"
echo "[INFO] Alert file: /var/log/snort/alert"
ls -la /var/log/snort/ 2>/dev/null
echo ""
echo "[INFO] ============================================"
echo "[INFO] 🔴 LIVE ALERT MONITOR — Menunggu alert..."
echo "[INFO]    Gunakan: docker logs -f argonauth_snort_101032300005"
echo "[INFO]    Atau:    docker exec ... tail -f /var/log/snort/alert"
echo "[INFO] ============================================"

# Trap: kalau container di-stop, kill Snort juga
cleanup() {
    echo "[INFO] Stopping Snort (PID: $SNORT_PID)..."
    kill $SNORT_PID 2>/dev/null
    wait $SNORT_PID 2>/dev/null
    echo "[INFO] Snort stopped."
    exit 0
}
trap cleanup SIGTERM SIGINT

# Monitor alert file dan tampilkan ke stdout (docker logs)
# Gunakan tail -F (follow by name) agar tetap baca meski file di-recreate
tail -F /var/log/snort/alert 2>/dev/null &
TAIL_PID=$!

# Tunggu Snort selesai (container hidup selama Snort hidup)
wait $SNORT_PID 2>/dev/null
SNORT_EXIT=$?

# Snort berhenti — kill tail dan exit
kill $TAIL_PID 2>/dev/null
echo "[WARN] Snort berhenti dengan exit code: $SNORT_EXIT"
exit ${SNORT_EXIT:-1}

