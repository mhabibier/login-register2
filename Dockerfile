# Gunakan PHP 8.2 dengan Apache
FROM php:8.2-apache

# Install ekstensi mysqli untuk koneksi ke MySQL + curl untuk healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install mysqli && docker-php-ext-enable mysqli

# Aktifkan modul Apache yang diperlukan untuk HTTPS
RUN a2enmod ssl rewrite headers

# Salin konfigurasi Apache untuk HTTPS (menggunakan sertifikat mkcert)
COPY apache/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf

# Aktifkan site HTTPS
RUN a2ensite default-ssl

# Salin semua file project ke dalam folder web server Apache
COPY . /var/www/html/

# Berikan izin yang tepat
RUN chown -R www-data:www-data /var/www/html/

# Buka port 80 (HTTP redirect) dan 443 (HTTPS)
EXPOSE 80 443
