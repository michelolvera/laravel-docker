FROM php:apache

# Instalar dependencias
RUN apt-get update && apt-get install -y \
      libicu-dev \
      libpq-dev \
      libzip-dev \
    && rm -r /var/lib/apt/lists/* \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-install \
      intl \
      pcntl \
      pdo_mysql \
      pdo_pgsql \
      pgsql \
      zip \
      opcache

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Usar la configuracion por defecto de PHP
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Copia los archivos de Laravel y configuracion
COPY ./ /var/www/html/

# Mover archivo de configuracion de memoria de PHP
RUN mv "/var/www/html/php-memory.ini" "$PHP_INI_DIR/conf.d/docker-php-memory.ini"

# Use the PORT environment variable in Apache configuration files.
# RUN sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Configurar Cabeceras de Apache
RUN a2enmod headers

# Mover archivo de configuracion de sitio de Apache-Laravel
RUN mv "/var/www/html/laravel-site.conf" "/etc/apache2/sites-available/laravel.conf"
RUN a2dissite 000-default.conf && a2ensite laravel.conf && a2enmod rewrite

# Change uid and gid of apache to docker user uid/gid
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# Establecer directorio de trabajo
WORKDIR /var/www/html/

# Instalar dependencias de composer
RUN composer install --optimize-autoloader --no-dev

# Habilidar RW de Storage de Laravel
RUN chmod -R 777 ./storage

# Optimizar configuracion de Laravel
RUN php artisan config:cache

# Optimizar la carga de rutas
RUN php artisan route:cache

# Optimizar vistas
RUN php artisan view:cache
