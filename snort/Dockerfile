FROM ubuntu:22.04

LABEL maintainer="ArgonAuth Security <argonauth@tel-u.ac.id>"
LABEL description="Snort IDS Container — ArgonAuth Project"
LABEL version="2.0"

# Nonaktifkan interaktif apt
ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# Install dependencies
# ============================================================
RUN apt-get update && apt-get install -y \
    snort \
    iproute2 \
    wget \
    curl \
    tar \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Buat direktori yang dibutuhkan
# ============================================================
RUN mkdir -p /etc/snort/rules \
             /var/log/snort \
             /var/run/snort

# ============================================================
# Salin konfigurasi lokal
# ============================================================
COPY snort.conf /etc/snort/snort.conf

# ============================================================
# Salin rule lokal ArgonAuth (custom rules)
# ============================================================
COPY rules/argonauth.rules /etc/snort/rules/argonauth.rules

# ============================================================
# Download Community Rules dari Snort.org (manual update)
# Rules komunitas = rules yang dibuat dan dikurasi komunitas Snort
# ============================================================
RUN wget -q "https://www.snort.org/downloads/community/community-rules.tar.gz" \
        -O /tmp/community-rules.tar.gz \
    && tar -xzf /tmp/community-rules.tar.gz -C /tmp/ \
    && cp /tmp/community-rules/community.rules /etc/snort/rules/community.rules \
    && rm -rf /tmp/community-rules* \
    && echo "[Snort] Community rules downloaded: $(wc -l < /etc/snort/rules/community.rules) rules"

# ============================================================
# Salin script update rules manual
# ============================================================
COPY update-rules.sh /usr/local/bin/update-rules.sh
RUN chmod +x /usr/local/bin/update-rules.sh

# ============================================================
# Verifikasi instalasi Snort
# ============================================================
RUN snort --version 2>&1 | head -5

# ============================================================
# Jalankan Snort dalam mode IDS
# - Auto-detect interface jaringan (ens33, eth0, enp0s3, dll)
# - -A fast : simpan alert ke file
# - -q      : quiet mode
# - -c      : file konfigurasi
# - -l      : direktori log
# ============================================================
CMD ["sh", "-c", "\
    IFACE=$(ip route | grep default | awk '{print $5}' | head -1); \
    echo \"[Snort] Detected interface: $IFACE\"; \
    echo \"[Snort] Local rules: $(wc -l < /etc/snort/rules/argonauth.rules) lines\"; \
    echo \"[Snort] Community rules: $(wc -l < /etc/snort/rules/community.rules) rules\"; \
    snort -A fast -q \
          -c /etc/snort/snort.conf \
          -i $IFACE \
          -l /var/log/snort 2>&1 \
"]
