#!/bin/bash
# =============================================================
# Snort IDS Entrypoint — ArgonAuth DevSecOps
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
# ArgonAuth DevSecOps | NIM: 101032300005
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

