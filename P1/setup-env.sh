#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# CONTENIDORS

## Crea/arranca els contenidors si cal i espera que estiguen sans (healthy)
docker compose up -d --wait

# FITXERS DE CONFIGURACIO
docker cp conf/memoria.conf empresa-db:/var/lib/postgresql/data/memoria.conf
## 2. Indicar a postgresql.conf que incluya este archivo
docker exec -i empresa-db bash -c "echo \"include = 'memoria.conf'\" >> /var/lib/postgresql/data/postgresql.conf"

# EXEMPLE LLANÇAMENT CONSULTES SQL
docker exec -i empresa-db psql -U postgres < sql/consultes.sql