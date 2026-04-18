FROM ubuntu:22.04

LABEL maintainer="ArgonAuth Project — Keamanan Sistem"
LABEL description="Snort 2 IDS Container untuk monitoring traffic HTTPS ArgonAuth"

ENV DEBIAN_FRONTEND=noninteractive

# Install Snort dan dependensi
RUN apt-get update && apt-get install -y \
    snort \
    libpcap-dev \
    libpcre3-dev \
    libdnet-dev \
    iproute2 \
    net-tools \
    tcpdump \
    && rm -rf /var/lib/apt/lists/*

# Buat direktori yang diperlukan
RUN mkdir -p /var/log/snort \
             /var/log/snort/archive \
             /etc/snort/rules \
             /usr/local/lib/snort_dynamicrules

# Salin konfigurasi Snort
COPY snort.conf /etc/snort/snort.conf

# Salin custom rules ArgonAuth
COPY rules/ /etc/snort/rules/

# Set permission
RUN chmod 644 /etc/snort/snort.conf \
 && chmod 644 /etc/snort/rules/*.rules \
 && chmod 777 /var/log/snort

# Verifikasi instalasi
RUN snort --version 2>&1 | head -5

# Jalankan Snort dalam mode IDS
# Auto-detect interface jaringan (ens33, eth0, enp0s3, dll)
CMD ["sh", "-c", "IFACE=$(ip route | grep default | awk '{print $5}' | head -1); echo \"[Snort] Detected interface: $IFACE\"; snort -A fast -q -c /etc/snort/snort.conf -i $IFACE -l /var/log/snort 2>&1"]
