#!/bin/bash
# =============================================================
# Script Pengujian Snort Rules — ArgonAuth DevSecOps
# NIM: 101032300005
# Jalankan di VM Linux: bash snort/test_rules.sh
# =============================================================

APP_IP="172.20.0.2"
USER_CTR="argonauth_user_101032300005"
SNORT_CTR="argonauth_snort_101032300005"
APP_CTR="argonauth_app_101032300005"
DB_CTR="argonauth_db_101032300005"
DB_IP="172.21.0.2"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

pause() {
    echo ""
    echo -e "${YELLOW}>>> Cek Terminal A untuk alert, lalu tekan ENTER untuk lanjut...${NC}"
    read -r
}

echo "============================================================="
echo "     ArgonAuth — Pengujian Snort IDS Rules"
echo "     NIM: 101032300005"
echo "============================================================="
echo ""

# =============================================================
# FASE 0: VERIFIKASI INFRASTRUKTUR
# =============================================================
echo -e "${CYAN}========== FASE 0: VERIFIKASI INFRASTRUKTUR ==========${NC}"
echo ""

echo -e "${GREEN}[0.1] Status Semua Container:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo -e "${GREEN}[0.2] Healthcheck:${NC}"
echo "  App:   $(docker inspect $APP_CTR --format '{{.State.Health.Status}}' 2>/dev/null || echo 'N/A')"
echo "  DB:    $(docker inspect $DB_CTR --format '{{.State.Health.Status}}' 2>/dev/null || echo 'N/A')"
echo "  Snort: $(docker inspect $SNORT_CTR --format '{{.State.Health.Status}}' 2>/dev/null || echo 'N/A')"
echo ""

echo -e "${GREEN}[0.3] Verifikasi NIM di Container Name:${NC}"
docker ps --format "{{.Names}}" | grep 101032300005
echo ""

echo -e "${GREEN}[0.4] Verifikasi NIM Label (Snort):${NC}"
echo "  NIM: $(docker inspect $SNORT_CTR --format '{{index .Config.Labels "com.argonauth.nim"}}' 2>/dev/null)"
echo ""

echo -e "${GREEN}[0.5] Network Segmentation:${NC}"
echo "  Frontend Network:"
docker network inspect argonauth_frontend --format '{{range .Containers}}    - {{.Name}}{{println}}{{end}}' 2>/dev/null
echo "  Backend Network:"
docker network inspect argonauth_backend --format '{{range .Containers}}    - {{.Name}}{{println}}{{end}}' 2>/dev/null
echo ""

echo -e "${GREEN}[0.6] IP Container:${NC}"
echo "  App:  $(docker inspect $APP_CTR --format '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' 2>/dev/null)"
echo "  DB:   $(docker inspect $DB_CTR --format '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' 2>/dev/null)"
echo "  User: $(docker inspect $USER_CTR --format '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' 2>/dev/null)"
echo ""

echo -e "${GREEN}[0.7] Snort Interface:${NC}"
docker logs $SNORT_CTR 2>&1 | grep -E "(Interface|terdeteksi)" | tail -1
echo ""

echo -e "${YELLOW}============================================================="
echo "  FASE 0 SELESAI — Screenshot hasil di atas!"
echo "  Pastikan semua healthy sebelum lanjut."
echo "=============================================================${NC}"
pause

# =============================================================
# PERSIAPAN: Buka Terminal A untuk monitor
# =============================================================
echo -e "${RED}============================================================="
echo "  PENTING: Buka TERMINAL BARU (Terminal A) dan jalankan:"
echo ""
echo "  docker exec $SNORT_CTR tail -f /var/log/snort/alert"
echo ""
echo "  Biarkan Terminal A terus jalan untuk monitor alert."
echo "=============================================================${NC}"
pause

# =============================================================
# FASE 1: ICMP
# =============================================================
echo -e "${CYAN}========== FASE 1: ICMP — Ping & Flood ==========${NC}"
echo ""

echo -e "${GREEN}[1.1] SID 9001001 — ICMP Ping Detected${NC}"
echo "  Mengirim 5 ping ke $APP_IP..."
docker exec $USER_CTR ping -c 5 $APP_IP
pause

echo -e "${GREEN}[1.2] SID 9001002 — ICMP Flood Detected${NC}"
echo "  Mengirim 20 ping cepat (interval 0.1s)..."
docker exec $USER_CTR ping -c 20 -i 0.1 $APP_IP
pause

# =============================================================
# FASE 2: HTTP ACCESS
# =============================================================
echo -e "${CYAN}========== FASE 2: HTTP — Akses Web (Port 80) ==========${NC}"
echo ""

echo -e "${GREEN}[2.1] SID 9001010 — HTTP GET login.php${NC}"
docker exec $USER_CTR curl -s -o /dev/null -w "  HTTP Status: %{http_code}\n" http://$APP_IP/login.php
pause

echo -e "${GREEN}[2.2] SID 9001011 — HTTP POST login.php (Login Attempt)${NC}"
docker exec $USER_CTR curl -s -o /dev/null -w "  HTTP Status: %{http_code}\n" \
  -X POST http://$APP_IP/login.php \
  -d "username=admin&password=test123"
pause

echo -e "${GREEN}[2.3] SID 9001012 — HTTP GET registrasi.php${NC}"
docker exec $USER_CTR curl -s -o /dev/null -w "  HTTP Status: %{http_code}\n" http://$APP_IP/registrasi.php
pause

# =============================================================
# FASE 3: BRUTE FORCE
# =============================================================
echo -e "${CYAN}========== FASE 3: BRUTE FORCE — Login Berulang ==========${NC}"
echo ""

echo -e "${GREEN}[3.1] SID 9001020 — Brute Force (6x POST dalam 3 detik)${NC}"
docker exec $USER_CTR sh -c 'for i in 1 2 3 4 5 6; do
  curl -s -o /dev/null -X POST http://'"$APP_IP"'/login.php -d "username=admin&password=salah";
  echo "  Request $i terkirim";
  sleep 0.5;
done'
pause

echo -e "${GREEN}[3.2] SID 9001021 — Brute Force Agresif (16x POST)${NC}"
docker exec $USER_CTR sh -c 'for i in $(seq 1 16); do
  curl -s -o /dev/null -X POST http://'"$APP_IP"'/login.php -d "username=admin&password=hack";
  echo "  Request $i terkirim";
  sleep 0.3;
done'
pause

echo -e "${GREEN}[3.3] SID 9001022 — HTTP GET Flood (35x GET)${NC}"
docker exec $USER_CTR sh -c 'for i in $(seq 1 35); do
  curl -s -o /dev/null http://'"$APP_IP"'/login.php;
  sleep 0.1;
done'
echo "  35 request GET terkirim"
pause

# =============================================================
# FASE 4: PORT SCAN
# =============================================================
echo -e "${CYAN}========== FASE 4: PORT SCAN — Nmap Stealth Scan ==========${NC}"
echo ""

echo -e "${GREEN}[4.1] SID 9001030 — TCP SYN Scan${NC}"
docker exec $USER_CTR nmap -sS $APP_IP
pause

echo -e "${GREEN}[4.2] SID 9001031 — TCP NULL Scan${NC}"
docker exec $USER_CTR nmap -sN $APP_IP
pause

echo -e "${GREEN}[4.3] SID 9001032 — TCP FIN Scan${NC}"
docker exec $USER_CTR nmap -sF $APP_IP
pause

echo -e "${GREEN}[4.4] SID 9001033 — TCP XMAS Scan${NC}"
docker exec $USER_CTR nmap -sX $APP_IP
pause

# =============================================================
# FASE 5: DATABASE ISOLATION
# =============================================================
echo -e "${CYAN}========== FASE 5: DATABASE — ACL Network Segmentation ==========${NC}"
echo ""

echo -e "${GREEN}[5.1] SID 9001040 — Akses MySQL dari User Container${NC}"
echo "  Mencoba koneksi ke $DB_IP:3306 dari user container..."
docker exec $USER_CTR sh -c "nc -zv -w 3 $DB_IP 3306 2>&1 || echo '  BLOCKED — DB terisolasi di backend_net!'"
echo ""
echo -e "${YELLOW}  Catatan: Koneksi gagal = ACL bekerja. DB hanya bisa diakses dari container app.${NC}"
pause

# =============================================================
# FASE 6: HTTPS MONITOR
# =============================================================
echo -e "${CYAN}========== FASE 6: HTTPS — Monitor Koneksi TLS ==========${NC}"
echo ""

echo -e "${GREEN}[6.1] SID 9001050 — New HTTPS Connection (port 443)${NC}"
docker exec $USER_CTR curl -k -s -o /dev/null -w "  HTTPS Status: %{http_code}\n" https://$APP_IP/login.php
pause

echo -e "${GREEN}[6.2] SID 9001051 — New HTTPS Connection (port 8443)${NC}"
docker exec $USER_CTR curl -k -s -o /dev/null -w "  HTTPS Status: %{http_code}\n" https://$APP_IP:8443/login.php 2>/dev/null || echo "  Port 8443 tidak tersedia (normal jika app tidak listen di port ini)"
pause

# =============================================================
# FASE 7: DoS ATTACK
# =============================================================
echo -e "${CYAN}========== FASE 7: DoS — ICMP Redirect & UDP Flood ==========${NC}"
echo ""

echo -e "${GREEN}[7.1] SID 9001003 — ICMP Redirect Attack${NC}"
docker exec $USER_CTR hping3 --icmp --icmptype 5 $APP_IP -c 3 2>&1 || echo "  hping3 tidak tersedia, skip"
pause

echo -e "${GREEN}[7.2] SID 9001004 — UDP Flood${NC}"
docker exec $USER_CTR hping3 --udp -p 80 --fast $APP_IP -c 100 2>&1 || echo "  hping3 tidak tersedia, skip"
pause

# =============================================================
# FASE 8: EXPORT & VERIFIKASI AKHIR
# =============================================================
echo -e "${CYAN}========== FASE 8: EXPORT & VERIFIKASI AKHIR ==========${NC}"
echo ""

echo -e "${GREEN}[8.1] Ringkasan Semua Alert ArgonAuth:${NC}"
docker exec $SNORT_CTR cat /var/log/snort/alert 2>/dev/null | grep -o "\[ArgonAuth\].*" | sort | uniq -c | sort -rn
echo ""

echo -e "${GREEN}[8.2] Export Alert ke File:${NC}"
docker exec $SNORT_CTR cat /var/log/snort/alert > ~/snort_test_results.txt 2>/dev/null
echo "  Disimpan ke ~/snort_test_results.txt"
echo ""

echo -e "${GREEN}[8.3] Healthcheck Final:${NC}"
echo "  App:   $(docker inspect $APP_CTR --format '{{.State.Health.Status}}' 2>/dev/null)"
echo "  DB:    $(docker inspect $DB_CTR --format '{{.State.Health.Status}}' 2>/dev/null)"
echo "  Snort: $(docker inspect $SNORT_CTR --format '{{.State.Health.Status}}' 2>/dev/null)"
echo ""

echo -e "${GREEN}[8.4] NIM Verification:${NC}"
docker ps --format "{{.Names}}" | grep 101032300005
echo ""

echo "============================================================="
echo -e "${GREEN}     PENGUJIAN SELESAI!"
echo "     Total: 17 Rules + Infrastruktur + Healthcheck"
echo "     File hasil: ~/snort_test_results.txt${NC}"
echo "============================================================="
