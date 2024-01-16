#!/bin/bash
set -e

# Define color functions
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function print_green {
    echo -e "${GREEN}$1${NC}"
}

function print_red {
    echo -e "${RED}$1${NC}"
}

# Define file paths
DOCKER_COMPOSE_FILE="docker-compose.yml"
DOCKER_COMPOSE_EXAMPLE_FILE="docker-compose.yml.example"
ENV_FILE=".env"
ENV_EXAMPLE_FILE=".env.example"

# Check if docker-compose.yaml exists, if not copy example file
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    print_green "📋 $DOCKER_COMPOSE_FILE does not exist, copying from example file..."
    cp "$DOCKER_COMPOSE_EXAMPLE_FILE" "$DOCKER_COMPOSE_FILE"
else
    print_red "⚠️  $DOCKER_COMPOSE_FILE already exists, not copying from example file..."
fi

# Check if .env exists, if not copy example file
if [ ! -f "$ENV_FILE" ]; then
    print_green "📋 $ENV_FILE does not exist, copying from example file..."
    cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
else
    print_red "⚠️  $ENV_FILE already exists, not copying from example file..."
fi

# Install composer dependencies
print_green "🔧 Installing composer dependencies..."
docker run --rm -u $(id -u):$(id -g) -v $(pwd):/opt -w /opt laravelsail/php82-composer:latest composer install --ignore-platform-req=ext-sockets --ignore-platform-req=ext-calendar --ignore-platform-req=ext-intl --ignore-platform-req=ext-pdo_mysql --ignore-platform-req=ext-gd --ignore-platform-req=ext-exif

# Start docker containers
print_green "🚀 Starting docker containers..."
./vendor/bin/sail up -d

# Wait for PostgreSQL to start
print_green "⏳ Waiting for Mysql to start.."
until docker exec bagisto-mysql mysqladmin -u root -p'secret' status > /dev/null 2>&1; do
  sleep 1
done

print_green "✅ Mysql started"
# Generate an application key
./vendor/bin/sail artisan key:generate --quiet
print_green "🔑 Application key generated"

# Migrate the database
print_green "🔧 Migrating the database..."
./vendor/bin/sail artisan migrate --seed
print_green "🗃️ Database migrated"

# Install GraphQL API
print_green "🔧 Installing GraphQL API..."
./vendor/bin/sail artisan bagisto-graphql:install
print_green "📦 GraphQL API installed"

# Started message
print_green "🚀 Started! Enjoy your development 😄"
