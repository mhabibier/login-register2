#!/bin/bash
# ============================================================
# update-rules.sh — Script Update Manual Snort Rules
# ArgonAuth Project | Keamanan Sistem
#
# Cara pakai:
#   Di dalam container: /usr/local/bin/update-rules.sh
#   Dari host: docker exec argonauth_snort_101032300005 update-rules.sh
# ============================================================

set -e

RULES_DIR="/etc/snort/rules"
LOG_FILE="/var/log/snort/update-rules.log"
COMMUNITY_URL="https://www.snort.org/downloads/community/community-rules.tar.gz"

echo "============================================" | tee -a $LOG_FILE
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Update Snort Rules dimulai..." | tee -a $LOG_FILE
echo "============================================" | tee -a $LOG_FILE

# --- 1. Backup rules lama ---
echo "[Step 1] Backup community rules lama..." | tee -a $LOG_FILE
if [ -f "$RULES_DIR/community.rules" ]; then
    cp "$RULES_DIR/community.rules" "$RULES_DIR/community.rules.bak"
    OLD_COUNT=$(wc -l < "$RULES_DIR/community.rules.bak")
    echo "  Backup: $OLD_COUNT rules lama disimpan ke community.rules.bak" | tee -a $LOG_FILE
fi

# --- 2. Download community rules terbaru ---
echo "[Step 2] Download community rules dari Snort.org..." | tee -a $LOG_FILE
wget -q "$COMMUNITY_URL" -O /tmp/community-rules.tar.gz

if [ $? -ne 0 ]; then
    echo "[ERROR] Download gagal! Cek koneksi internet." | tee -a $LOG_FILE
    exit 1
fi

# --- 3. Extract dan install ---
echo "[Step 3] Extract dan install rules baru..." | tee -a $LOG_FILE
tar -xzf /tmp/community-rules.tar.gz -C /tmp/
cp /tmp/community-rules/community.rules "$RULES_DIR/community.rules"
rm -rf /tmp/community-rules* /tmp/community-rules.tar.gz

NEW_COUNT=$(wc -l < "$RULES_DIR/community.rules")
echo "  Installed: $NEW_COUNT rules baru" | tee -a $LOG_FILE

# --- 4. Verifikasi config Snort masih valid ---
echo "[Step 4] Verifikasi konfigurasi Snort..." | tee -a $LOG_FILE
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)

snort -T -c /etc/snort/snort.conf -i "$IFACE" 2>&1 | tail -5 | tee -a $LOG_FILE

if [ $? -eq 0 ]; then
    echo "[OK] Konfigurasi valid!" | tee -a $LOG_FILE
else
    echo "[WARN] Konfigurasi mungkin ada masalah, rollback ke backup..." | tee -a $LOG_FILE
    cp "$RULES_DIR/community.rules.bak" "$RULES_DIR/community.rules"
fi

echo "============================================" | tee -a $LOG_FILE
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Update selesai." | tee -a $LOG_FILE
echo "  Local rules (argonauth.rules) : $(wc -l < $RULES_DIR/argonauth.rules) lines" | tee -a $LOG_FILE
echo "  Community rules               : $NEW_COUNT rules" | tee -a $LOG_FILE
echo "============================================" | tee -a $LOG_FILE
