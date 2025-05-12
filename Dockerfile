# ./Dockerfile  (two-stage to keep final image slim)
FROM ghcr.io/laravelphp/php-fpm:8.3 AS base

# ---------- build stage ----------
FROM base AS build
WORKDIR /var/www/html
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . .
RUN composer install --prefer-dist --no-dev --optimize-autoloader \
 && php artisan config:cache route:cache view:cache

# ---------- runtime stage ----------
FROM base
WORKDIR /var/www/html
# system deps required by swoole
RUN apt-get update && apt-get install -y libpq-dev libzip-dev git unzip \
 && pecl install swoole \
 && docker-php-ext-enable swoole
COPY --from=build /var/www/html /var/www/html
EXPOSE 8080
CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=8080", "--workers=auto", "--max-requests=1000", "--watch"]
