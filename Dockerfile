# Use the official PHP image with Nginx
FROM php:8.2-fpm

# Install required extensions and tools
RUN apt-get update && apt-get install -y \
    nginx \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip pdo pdo_mysql

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the working directory
WORKDIR /var/www/html

# Copy only the composer files first to leverage Docker cache
COPY composer.json composer.lock ./

# Debugging step: Check if composer.json is present
RUN ls -la /var/www/html/

# Install PHP dependencies with memory limit and verbosity
RUN composer install --no-dev --optimize-autoloader --no-scripts --prefer-dist --ignore-platform-reqs --memory-limit=-1 -vvv

# Copy the rest of the application files
COPY . .

# Set the appropriate permissions for storage and bootstrap/cache directories
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Configure Nginx
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

# Expose port 80 to the outside world
EXPOSE 80

# Start both Nginx and PHP-FPM
CMD service nginx start && php-fpm
