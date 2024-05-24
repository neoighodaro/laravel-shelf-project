#!/bin/bash
set -e

WHITE='\033[1;37m'
NC='\033[0m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'

# ----------------------------------------------------------------------------------------------------------------------
# Config
# ----------------------------------------------------------------------------------------------------------------------

container_mode=${CONTAINER_MODE:-http}
container_environment=${APP_ENV:-local}
container_server=${CONTAINER_SERVER:-frankenphp}
use_opcache=${USE_OPCACHE:-false}
fresh_migrations=${ALWAYS_FRESH_MIGRATIONS:-false}

# ----------------------------------------------------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------------------------------------------------

initialStuff() {
    echo -e "${WHITE}ℹ️ Initializing...${NC}"

    if [[ "$container_environment" == "local" ]]; then
        echo -e "${WHITE}ℹ️ Running composer install in dev mode...${NC}"
        composer install

        php artisan migrate:fresh --seed

        echo -e "${WHITE}ℹ️ Clearing caches...${NC}"
        php artisan optimize:clear
        php artisan cache:clear file
    else
        echo -e "${WHITE}ℹ️ Running composer install in production mode...${NC}"
        composer install --no-ansi --no-dev --prefer-dist --optimize-autoloader
        composer clear-cache

        if [[ "$fresh_migrations" == "true" ]]; then
            php artisan migrate:fresh --seed
        else
            php artisan migrate --force;
        fi

        if [[ "$use_opcache" == "true" ]]; then
            echo -e "${WHITE}ℹ️ Running opcache:compile...${NC}"
            php artisan opcache:compile --force;
        fi

        echo -e "${WHITE}ℹ️ Clearing caches...${NC}"
        php artisan optimize:clear
        php artisan cache:clear file

        echo -e "${WHITE}ℹ️ Optimizing application...${NC}"
        php artisan event:cache
        php artisan config:cache
        php artisan route:cache
    fi
}

function runSupervisorWithConf() {
    ALLOWED_SUPERVISOR_CONFIGS=("frankenphp" "octane" "horizon" "scheduler")
    if [[ ! " ${ALLOWED_SUPERVISOR_CONFIGS[@]} " =~ " ${1} " ]]; then
        echo -e "${RED}⚠️ Invalid supervisor config: ${1}. Allowed values: ${ALLOWED_SUPERVISOR_CONFIGS[@]}${NC}"
        exit 1
    fi

    echo -e "${WHITE}🚀 Running Supervisor with config: ${1}...${NC}"
    exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.${1}.conf
}

# ----------------------------------------------------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------------------------------------------------

echo "
   ______       _____  ___             _         __
  / __/ /  ___ / / _/ / _ \_______    (_)__ ____/ /_
 _\ \/ _ \/ -_) / _/ / ___/ __/ _ \  / / -_) __/ __/
/___/_//_/\__/_/_/  /_/  /_/  \___/_/ /\__/\__/\__/
                                 |___/
"
echo -e "${GREEN}ℹ️ Container mode: ${container_mode} | Environment: ${container_environment}${NC}"

cd /var/www/html

if [ "$1" != "" ]; then
    exec docker-php-entrypoint "$@"
elif [ ${container_mode} = "http" ]; then
    initialStuff

    if [[ "$container_environment" != "local" ]]; then
        if [[ "$use_opcache" == "true" ]]; then
            echo -e "${WHITE}ℹ️ Running opcache:compile...${NC}"
            php artisan opcache:compile --force;
        fi
    fi

    runSupervisorWithConf ${container_server}
elif [ ${container_mode} = "horizon" ]; then
    initialStuff
    runSupervisorWithConf "horizon"
elif [ ${container_mode} = "scheduler" ]; then
    initialStuff
    runSupervisorWithConf "scheduler"
else
    echo -e "${RED}⚠️ Invalid container mode: ${container_mode}${NC}"
    exit 1
fi
