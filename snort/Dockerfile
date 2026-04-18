FROM ubuntu:22.04

LABEL maintainer="ArgonAuth Security <argonauth@tel-u.ac.id>"
LABEL description="Snort IDS Container — ArgonAuth Project"
LABEL version="2.1"

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
# Buat dedicated Linux user 'snort' (security best practice)
# Snort TIDAK boleh jalan sebagai root
# ============================================================
RUN groupadd --system snort 2>/dev/null || true \
    && useradd --system \
               --no-create-home \
               --shell /sbin/nologin \
               --gid snort \
               --comment "Snort IDS Service User" \
               snort 2>/dev/null || true \
    && echo "[Snort] User 'snort' created successfully"

# ============================================================
# Buat direktori dan set ownership ke user snort
# ============================================================
RUN mkdir -p /etc/snort/rules \
             /var/log/snort \
             /var/run/snort \
    && chown -R snort:snort /etc/snort \
    && chown -R snort:snort /var/log/snort \
    && chown -R snort:snort /var/run/snort

# ============================================================
# Salin konfigurasi lokal (sebagai root, lalu ubah ownership)
# ============================================================
COPY snort.conf /etc/snort/snort.conf
RUN chown snort:snort /etc/snort/snort.conf

# ============================================================
# Salin rule lokal ArgonAuth (custom rules)
# ============================================================
COPY rules/argonauth.rules /etc/snort/rules/argonauth.rules
RUN chown snort:snort /etc/snort/rules/argonauth.rules

# ============================================================
# Download Community Rules dari Snort.org (manual update)
# Rules komunitas = rules yang dibuat dan dikurasi komunitas Snort
# ============================================================
RUN wget -q "https://www.snort.org/downloads/community/community-rules.tar.gz" \
        -O /tmp/community-rules.tar.gz \
    && tar -xzf /tmp/community-rules.tar.gz -C /tmp/ \
    && cp /tmp/community-rules/community.rules /etc/snort/rules/community.rules \
    && chown snort:snort /etc/snort/rules/community.rules \
    && rm -rf /tmp/community-rules* \
    && echo "[Snort] Community rules downloaded: $(wc -l < /etc/snort/rules/community.rules) rules"

# ============================================================
# Salin script update rules manual
# ============================================================
COPY update-rules.sh /usr/local/bin/update-rules.sh
RUN chmod +x /usr/local/bin/update-rules.sh

# ============================================================
# Verifikasi instalasi Snort dan user
# ============================================================
RUN snort --version 2>&1 | head -3 \
    && echo "[Snort] Running as user: $(id snort)" \
    && echo "[Snort] Rules directory: $(ls /etc/snort/rules/)"

# ============================================================
# Jalankan Snort sebagai user 'snort' (BUKAN root)
# ============================================================
USER snort

# ============================================================
# CMD: Auto-detect interface, lalu jalankan Snort
# Snort membutuhkan NET_ADMIN dan NET_RAW capability (set di docker-compose)
# ============================================================
CMD ["sh", "-c", "\
    IFACE=$(ip route 2>/dev/null | grep default | awk '{print $5}' | head -1); \
    if [ -z \"$IFACE\" ]; then IFACE=ens33; fi; \
    echo \"[Snort] Running as user: $(whoami)\"; \
    echo \"[Snort] Detected interface: $IFACE\"; \
    echo \"[Snort] Local rules (argonauth.rules): $(wc -l < /etc/snort/rules/argonauth.rules) lines\"; \
    echo \"[Snort] Community rules: $(wc -l < /etc/snort/rules/community.rules) rules\"; \
    snort -A fast -q \
          -c /etc/snort/snort.conf \
          -i $IFACE \
          -u snort -g snort \
          -l /var/log/snort 2>&1 \
"]
