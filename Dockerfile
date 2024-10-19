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
    && docker-php-ext-install gd zip

# Set the working directory
WORKDIR /var/www/html

# Copy only the composer files first to leverage Docker cache
COPY composer.json composer.lock ./

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Clear Composer cache and install PHP dependencies
RUN composer clear-cache
RUN composer install --no-dev --optimize-autoloader

# Copy the rest of the application files
COPY . .

# Create .env file from .env.example
RUN cp .env.example .env

# Generate the Laravel APP_KEY to ensure artisan commands work
RUN php artisan key:generate

# Set the appropriate permissions for storage and bootstrap/cache directories
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Copy Nginx configuration
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

# Expose port 80 to the outside world
EXPOSE 80

# Start both Nginx and PHP-FPM
CMD service nginx start && php-fpm
