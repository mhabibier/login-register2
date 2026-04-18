FROM ubuntu:22.04

LABEL maintainer="ArgonAuth DevSecOps"
LABEL description="Snort 2 IDS Container"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    snort \
    libpcap-dev \
    iproute2 \
    net-tools \
    iputils-ping \
    curl \
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
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
