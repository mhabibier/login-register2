FROM ubuntu:22.04

LABEL maintainer="ArgonAuth DevSecOps | NIM: 101032300005"
LABEL description="Snort 2 IDS Container — ArgonAuth DevSecOps Project"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    snort \
    libpcap-dev \
    iproute2 \
    net-tools \
    iputils-ping \
    curl \
    wget \
    tar \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Buat user snort (non-root)
RUN groupadd -r snort 2>/dev/null || true && \
    useradd -r -g snort -s /sbin/nologin snort 2>/dev/null || true

# Buat direktori yang dibutuhkan
RUN mkdir -p /var/log/snort /etc/snort/rules /etc/snort/so_rules /etc/snort/preproc_rules && \
    touch /var/log/snort/snort.alert.fast && \
    chown -R snort:snort /var/log/snort

# Salin konfigurasi
COPY snort.conf /etc/snort/snort.conf
COPY rules/argonauth.rules /etc/snort/rules/argonauth.rules

# Salin placeholder community rules (akan diisi auto-update saat startup)
COPY rules/emerging-threats.rules /etc/snort/rules/emerging-threats.rules

# Salin script entrypoint dan manual update
COPY entrypoint.sh /entrypoint.sh
COPY update_rules.sh /usr/local/bin/update_rules.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/update_rules.sh

ENTRYPOINT ["/entrypoint.sh"]
