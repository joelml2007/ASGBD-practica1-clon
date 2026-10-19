#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

### 1. CONTENEDORES
# Arranca los servicios y espera al primer healthcheck
docker compose up -d --wait

### 2. ARCHIVOS DE CONFIGURACIÓN
# Copia la configuración de memoria y HBA al volumen de datos
docker cp conf/memoria.conf empresa-db:/var/lib/postgresql/data/memoria.conf

# Incluye memoria.conf en postgresql.conf si no está ya presente
docker exec -i empresa-db bash -c "grep -q \"include = 'memoria.conf'\" /var/lib/postgresql/data/postgresql.conf || echo \"include = 'memoria.conf'\" >> /var/lib/postgresql/data/postgresql.conf"

### 3. REINICIO Y ESPERA
# Reinicia el servicio para aplicar los parámetros estáticos (shared_buffers, max_connections)
docker compose restart db

# Espera a que el healthcheck vuelva a dar OK antes de continuar
echo "Esperando a que la base de datos vuelva a estar disponible..."
until docker exec empresa-db pg_isready -h 127.0.0.1 -U postgres > /dev/null 2>&1; do
    sleep 1
done

### 4. CONSULTAS SQL (Tablespaces, usuarios, roles)
# docker exec -i empresa-db psql -U postgres < sql/tablespaces.sql