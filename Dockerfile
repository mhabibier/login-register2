# Gunakan PHP 8.2 dengan Apache
FROM php:8.2-apache

# Install ekstensi mysqli untuk koneksi ke MySQL
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

# Salin semua file project ke dalam folder web server Apache
COPY . /var/www/html/

# Berikan izin yang tepat
RUN chown -R www-data:www-data /var/www/html/

# Buka port 80
EXPOSE 80
