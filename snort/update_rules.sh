#!/bin/bash
# =============================================================
# update_rules.sh — Manual Update Emerging Threats Community Rules
# ArgonAuth Kamsis | NIM: 101032300005
#
# Cara pakai (manual update dari host):
#   docker exec argonauth_snort_101032300005 /usr/local/bin/update_rules.sh
#
# Cara pakai (dari dalam container):
#   /usr/local/bin/update_rules.sh
# =============================================================

set -euo pipefail

RULES_DIR="/etc/snort/rules"
ET_OUTPUT="${RULES_DIR}/emerging-threats.rules"
ET_BASE_URL="https://rules.emergingthreats.net/open/snort-2.9.0/rules"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ---- Rule komunitas yang relevan untuk web app security ----
# Sumber: https://rules.emergingthreats.net (Open Ruleset — gratis)
ET_RULES=(
    "emerging-web-server.rules"   # Serangan HTTP / web server
    "emerging-dos.rules"          # DoS / DDoS attacks
    "emerging-scan.rules"         # Port scan & recon
    "emerging-sql.rules"          # SQL injection
)

echo "============================================================"
echo "  ArgonAuth — Update Emerging Threats Community Rules"
echo "  NIM   : 101032300005"
echo "  Waktu : ${TIMESTAMP}"
echo "  Output: ${ET_OUTPUT}"
echo "============================================================"
echo ""

# ---- Pastikan direktori rules ada ----
mkdir -p "${RULES_DIR}"

# ---- Tulis header file output ----
cat > "${ET_OUTPUT}" << EOF
# =============================================================
# emerging-threats.rules — Emerging Threats Open Ruleset
# ArgonAuth Kamsis | NIM: 101032300005
#
# Sumber  : https://rules.emergingthreats.net/open/snort-2.9.0/rules/
# Update  : ${TIMESTAMP}
# Lisensi : BSD License (Open Ruleset)
#
# Rule yang diinclude:
#   - emerging-web-server.rules  (HTTP attack detection)
#   - emerging-dos.rules         (DoS/DDoS detection)
#   - emerging-scan.rules        (Port scan detection)
#   - emerging-sql.rules         (SQL Injection detection)
# =============================================================

EOF

TOTAL_RULES=0
FAILED=0
SUCCESS=0

# ---- Download setiap file rule ----
for RULE_FILE in "${ET_RULES[@]}"; do
    URL="${ET_BASE_URL}/${RULE_FILE}"
    TEMP_FILE="/tmp/${RULE_FILE}"

    printf "[INFO] Downloading %-35s ... " "${RULE_FILE}"

    if curl -sS --max-time 30 --retry 2 --retry-delay 3 \
            -A "ArgonAuth-Snort-Updater/1.0" \
            -o "${TEMP_FILE}" "${URL}" 2>/dev/null; then

        # Pastikan COUNT selalu integer bersih (hindari printf error)
        COUNT=$(grep -cE "^(alert|drop|reject|pass)" "${TEMP_FILE}" 2>/dev/null || true)
        COUNT=$((COUNT + 0))  # Force ke integer
        printf "OK  (%4d rules)\n" "$COUNT"

        # Tulis header section dan isi rules
        {
            echo ""
            echo "# ================================================================"
            echo "# ${RULE_FILE}"
            echo "# Downloaded: ${TIMESTAMP}"
            echo "# ================================================================"
            cat "${TEMP_FILE}"
        } >> "${ET_OUTPUT}"

        TOTAL_RULES=$((TOTAL_RULES + COUNT))
        SUCCESS=$((SUCCESS + 1))
        rm -f "${TEMP_FILE}"

    else
        printf "FAIL\n"
        echo "# [GAGAL DOWNLOAD] ${RULE_FILE} — ${TIMESTAMP}" >> "${ET_OUTPUT}"
        FAILED=$((FAILED + 1))
    fi
done

# ---- Simpan metadata update ----
{
    echo "last_update=${TIMESTAMP}"
    echo "total_rules=${TOTAL_RULES}"
    echo "success=${SUCCESS}"
    echo "failed=${FAILED}"
} > "${RULES_DIR}/.community_rules_meta"

# Append ICMP rules ke community rules
cat >> "${ET_OUTPUT}" << 'ICMP_RULES'

# ================================================================
# ICMP Detection (Custom Addition)
# ================================================================
alert icmp any any -> $HOME_NET any (msg:"[ET-Custom] ICMP Ping Detected"; itype:8; classtype:misc-activity; priority:1; sid:9901001; rev:1;)
alert icmp any any -> $HOME_NET any (msg:"[ET-Custom] ICMP Flood Detected"; itype:8; detection_filter:track by_src, count 10, seconds 5; classtype:attempted-dos; priority:1; sid:9901002; rev:1;)
ICMP_RULES
TOTAL_RULES=$((TOTAL_RULES + 2))
echo "[INFO] ICMP rules (priority 1) ditambahkan"

echo ""
echo "============================================================"
echo "  [SELESAI] Hasil Update Community Rules"
echo "  Total rules   : ${TOTAL_RULES}"
echo "  File berhasil : ${SUCCESS}/${#ET_RULES[@]}"
echo "  File gagal    : ${FAILED}/${#ET_RULES[@]}"
echo "  Disimpan di   : ${ET_OUTPUT}"
echo "============================================================"

# ---- Exit code ----
if [ "${FAILED}" -eq "${#ET_RULES[@]}" ]; then
    echo ""
    echo "[ERROR] Semua download gagal! Periksa koneksi internet container."
    echo "        Snort tetap berjalan dengan rule lokal (argonauth.rules)"
    exit 1
fi

echo ""
echo "[OK] Update selesai. Rule komunitas siap digunakan."
exit 0
