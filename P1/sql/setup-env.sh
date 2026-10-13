#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

### CONTENIDORS

# Crea/arranca els contenidors si cal i espera que estiguen sans (healthy)
docker compose up -d --wait

### FITXERS DE CONFIGURACIO
docker cp config/...conf empresa-db:/var/lib/postgresql/data/...conf

### EXEMPLE LLANÇAMENT CONSULTES SQL
docker exec -i empresa-db psql -U postgres < sql/consultes.sql