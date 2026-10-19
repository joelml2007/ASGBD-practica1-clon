#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
    echo "No se encuentra el archivo .env" >&2
    exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a
: "${POSTGRES_USER:?POSTGRES_USER no está definido en .env}"

### 1. CONTENEDORES
# Borrar los contenedores existentes y sus volúmenes
docker compose down -v
# Arranca los servicios y espera al primer healthcheck
docker compose up -d --wait

### 2. ARCHIVOS DE CONFIGURACIÓN
# Copia la configuración de memoria y logging al volumen de datos
docker cp config/memoria.conf empresa-db:/var/lib/postgresql/data/memoria.conf
docker cp config/logging.conf empresa-db:/var/lib/postgresql/data/logging.conf
docker exec -i empresa-db bash -c "grep -q \"include = 'memoria.conf'\" /var/lib/postgresql/data/postgresql.conf || echo \"include = 'memoria.conf'\" >> /var/lib/postgresql/data/postgresql.conf"
# Incluye logging.conf en postgresql.conf
docker exec -i empresa-db bash -c "grep -q \"include = 'logging.conf'\" /var/lib/postgresql/data/postgresql.conf || echo \"include = 'logging.conf'\" >> /var/lib/postgresql/data/postgresql.conf"
### 3. REINICIO Y ESPERA
# Reinicia el servicio para aplicar los parámetros estáticos (shared_buffers, max_connections)
docker compose restart db 

# Espera a que el healthcheck vuelva a dar OK antes de continuar
echo "Esperando a que la base de datos vuelva a estar disponible..."
until docker exec empresa-db pg_isready -h 127.0.0.1 -U "$POSTGRES_USER" > /dev/null 2>&1; do
    sleep 1
done
## 4. Permisos para poder crear tablespaces
docker exec -i -u root empresa-db bash -c "chown -R postgres:postgres /mnt/vol_erp /mnt/vol_empl && chmod 700 /mnt/vol_erp /mnt/vol_empl"
### 4. CONSULTAS SQL (Tablespaces, usuarios, roles)
docker exec -i empresa-db psql -U "$POSTGRES_USER" < sql/01_tablespaces.sql
