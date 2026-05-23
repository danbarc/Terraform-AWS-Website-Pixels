#!/bin/bash
exec > /var/log/userdata.log 2>&1

echo "=== Starting Userdata Script - $(date) ==="

# Update system
apt-get update -y && apt-get upgrade -y

# Install required packages
apt-get install -y apache2 \
                   php8.4 \
                   libapache2-mod-php8.4 \
                   php8.4-mysql \
                   php8.4-curl \
                   php8.4-gd \
                   php8.4-mbstring \
                   php8.4-xml \
                   php8.4-zip \
                   php8.4-imagick \
                   unzip \
                   awscli \
                   curl

# Enable Apache modules
a2enmod rewrite expires headers

# Start Apache
systemctl enable apache2
systemctl start apache2

# PHP settings optimized for Duplicator
cat > /etc/php/8.4/apache2/conf.d/wordpress.ini << EOF
upload_max_filesize = 512M
post_max_size = 512M
memory_limit = 512M
max_execution_time = 600
max_input_vars = 5000
EOF

# Prepare web directory
mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Download Duplicator files from S3
echo "Downloading Duplicator files from S3..."
cd /var/www/html

curl -s -o installer.php https://pixels-dev-br-duplicator-files.s3.sa-east-1.amazonaws.com/installer.php
curl -s -o 20251101_pixelstecnologia_f7bd3cab9c35d1446160_20260517220100_archive.zip \
     https://pixels-dev-br-duplicator-files.s3.sa-east-1.amazonaws.com/20251101_pixelstecnologia_f7bd3cab9c35d1446160_20260517220100_archive.zip

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod 644 installer.php *.zip

echo "=== Duplicator files downloaded successfully ==="
echo "Installer ready at: http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/installer.php"

# Restart Apache
systemctl restart apache2

echo "=== Userdata completed successfully - $(date) ==="