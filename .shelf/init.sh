#!/usr/bin/env bash

# ----------------------------------------------------------------------------------------------------------------------
# Configurable Variables
# ----------------------------------------------------------------------------------------------------------------------

FRANKENPHP_VERSION=${FRANKENPHP_VERSION:-8.3-bookworm}
DB_CONNECTION=${DB_CONNECTION:-pgsql}
PROJECT_NAME=${PROJECT_NAME:-'Shelf Project'}
SLUGIFIED_PROJECT_NAME=$(echo $PROJECT_NAME | sed 's/\([^A-Z]\)\([A-Z0-9]\)/\1-\2/g' | sed 's/\([A-Z0-9]\)\([A-Z0-9]\)\([^A-Z]\)/\1-\2\3/g' | tr '[:upper:]' '[:lower:]')

APP_PORT=${APP_PORT:-8080}
FORWARD_DB_PORT=${FORWARD_DB_PORT:-5432}
FORWARD_REDIS_PORT=${FORWARD_REDIS_PORT:-6379}

# ----------------------------------------------------------------------------------------------------------------------
# Functions
# ----------------------------------------------------------------------------------------------------------------------

function replace_in_file() {
    sed -i "s/$1/$2/g" $3
}

function get_env_value() {
    echo $(grep $1 laravel/.env.example | cut -d '=' -f2)
}

function set_env_value() {
    sed -i "s/^$1=.*$/$1=$2/" "laravel/.env.example"
}

function uncomment_line() {
    sed -i "s/^#.*$1/$1/" "laravel/.env.example"
}

function comment_line() {
    sed -i "s/^$1/# $1/" "laravel/.env.example"
}

# ----------------------------------------------------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------------------------------------------------

cd $(dirname $0)/../

################################
# Prepare Dockerfile
################################

if [ -f "docker/Dockerfile" ]; then
    rm docker/Dockerfile
fi;

cp .shelf/stubs/Dockerfile.stub docker/Dockerfile
replace_in_file "\[\%FRANKENPHP_VERSION\%\]" "$FRANKENPHP_VERSION" docker/Dockerfile

if [ -f ".devcontainer/devcontainer.json" ]; then
    rm .devcontainer/devcontainer.json
fi;
cp .shelf/stubs/devcontainer.json.stub .devcontainer/devcontainer.json
replace_in_file "\[\%SLUGIFIED_PROJECT_NAME\%\]" "$SLUGIFIED_PROJECT_NAME" .devcontainer/devcontainer.json

################################
# Add Laravel project
################################

if [ -d "laravel" ]; then
    rm -rf laravel
fi

composer create-project --prefer-dist laravel/laravel laravel --no-progress --no-interaction

cd laravel
composer require ext-gd ext-intl ext-mbstring ext-pdo_pgsql ext-pdo_sqlite ext-redis ext-zend-opcache
composer require --dev friendsofphp/php-cs-fixer
cd ..

if [ -f "compose.yaml" ]; then
    rm compose.yaml
fi;
cp .shelf/stubs/compose.yaml.stub compose.yaml

################################
# Prepare .env file
################################

echo "#-------------------------------------------------------------------------------
# Docker: Local development ports.
#-------------------------------------------------------------------------------

APP_PORT=$APP_PORT
FORWARD_DB_PORT=$FORWARD_DB_PORT
FORWARD_REDIS_PORT=$FORWARD_REDIS_PORT

#-------------------------------------------------------------------------------
# Default Environment
#-------------------------------------------------------------------------------
" | cat - laravel/.env.example > temp && mv temp laravel/.env.example

uncomment_line 'DB_PORT=3306'
uncomment_line 'DB_HOST=127.0.0.1'
uncomment_line 'DB_DATABASE=laravel'
uncomment_line 'DB_USERNAME=root'
uncomment_line 'DB_PASSWORD='

set_env_value 'APP_NAME' "\"$PROJECT_NAME\""
set_env_value 'APP_URL' "http\:\/\/localhost:\${APP_PORT}"
set_env_value 'DB_CONNECTION' "$DB_CONNECTION"
set_env_value 'DB_HOST' 'pgsql'
set_env_value 'DB_PORT' "\${FORWARD_DB_PORT}"
set_env_value 'DB_USERNAME' "laravel"
set_env_value 'DB_PASSWORD' "secret"
set_env_value 'REDIS_PORT' "\${FORWARD_REDIS_PORT}"
set_env_value 'REDIS_HOST' 'redis'

################################
# Prepare docker-compose.yml
################################

replace_in_file "\[\%SLUGIFIED_PROJECT_NAME\%\]" "$SLUGIFIED_PROJECT_NAME" compose.yaml


################################
# clean up
################################

shopt -s dotglob nullglob
mv laravel/* .
rm -rf laravel
