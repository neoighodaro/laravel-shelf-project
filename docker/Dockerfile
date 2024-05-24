#syntax=docker/dockerfile:1.4

FROM dunglas/frankenphp:1.1-php8.3-bookworm AS frankenphp_upstream

##############################################################################################################
# Base
##############################################################################################################

FROM frankenphp_upstream as base

LABEL maintainer="Neo (@neoighodaro)"

ARG WWWUSER=9999
ARG WWWGROUP=9999
ARG TZ=UTC

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-color \
    SERVER_NAME=:80 \
    WITH_HORIZON=false \
    WITH_SCHEDULER=false \
    CONTAINER_SERVER=frankenphp \
    USER=octane \
    ROOT=/var/www/html \
    COMPOSER_FUND=0 \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
    XDG_CONFIG_HOME=/var/www/html/storage/app/psysh

WORKDIR ${ROOT}

RUN \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone

RUN \
    set -eux; \
    install-php-extensions @composer opcache pgsql redis pcntl pdo_pgsql pdo_sqlite zip gd intl;

RUN \
    apt-get update; \
    apt-get upgrade -yqq; \
    apt-get install -yqq --no-install-recommends --show-progress supervisor; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* ; \
    curl -sSL "https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64" -o /usr/bin/supercronic; \
    chmod +x /usr/bin/supercronic; \
    mkdir -p /etc/supercronic; \
    echo "*/1 * * * * php ${ROOT}/artisan schedule:run --verbose --no-interaction" > /etc/supercronic/laravel;

RUN \
    groupadd --force -g ${WWWGROUP} ${USER}; \
    useradd -ms /bin/bash --no-log-init --no-user-group -g ${WWWGROUP} -u ${WWWUSER} ${USER}; \
	setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp; \
	chown -R ${USER}:${USER} /data/caddy && chown -R ${USER}:${USER} /config/caddy; \
    mkdir -p ${ROOT} /var/log; \
    chown -R ${USER}:${USER} ${ROOT} /var/log; \
    chmod -R a+rw /var/log;

COPY --chmod=755 etc/bash_aliases /etc/aliases
COPY --chmod=755 etc/start-container.sh /usr/local/bin/start-container
COPY --chown=${USER}:${USER} supervisor/conf.d/supervisord.*.conf /etc/supervisor/conf.d/

EXPOSE 80

ENTRYPOINT ["start-container"]

# ----------------------------------------------------------------------------------------------------------------------
# Development
# ----------------------------------------------------------------------------------------------------------------------

FROM base as dev

RUN install-php-extensions xdebug; \
    cat /etc/aliases >> /home/${USER}/.bashrc;

COPY  docker/php/20-xdebug.ini $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini

USER ${USER}

# ----------------------------------------------------------------------------------------------------------------------
# Production
# ----------------------------------------------------------------------------------------------------------------------

FROM base as prod

COPY --chown=${USER}:${USER} . .
COPY --chmod=755 docker/php/99-octane.ini $PHP_INI_DIR/conf.d/99-octane.ini

RUN \
    cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini; \
    chmod -R 755 bootstrap/cache storage

USER ${USER}
