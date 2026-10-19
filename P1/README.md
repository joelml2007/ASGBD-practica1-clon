# PRACTICA 1
Este es el documento donde se explicará todo el trabajo relacionado con la práctica 1. 
## Tabla de resumen
|Requisitos  |Como se ha resuelto |Evidencia  |
|---------|---------|---------|
|1. Desplegación reproducible    |         |         |
|2. Acceso restringido a la red de la aplicación    |         |         |
|3. Memória    |         |         |
|4. Conexiones     |         |         |
|5. Almacenamiento     |         |         |
|6. Trazabilidad     |         |         |
|7. Cuenta de la aplicación     |         |         |
|7. Acceso del personal     |         |         |
|7. Ampliación: Caída repentina (opcional)     |         |         |

Utilizado postgres 16 por ser una versión estable y no usar una versión latest. 
Redes:
      ud1_interna:
        ipv4_address: 172.30.0.10/24
      ud1_visitantes:
        ipv4_address: 172.31.0.10/24
    Asignadas la .10 ya que las primeras IPs las suele utilizar docker.
    

credenciales en .env ocultado por .gitignore

se utiliza como clientes la misma imagen de postgres para evitar tener que instalar en otras imagenes el psql, ya que en postgres ya viene instalado. 


Se utiliza entrypoint: ["sleep", "infinity"] para evitar que inicializen  subase de datos

Se crea además un volumen de logs apuntando a /var/logs/postgresql para cumplir con el apartado 6

Limite conexiones de 60.

ERP: 3 instàncies × 15 connexions cadascuna = 45 connexions.   
Personal de RRHH: 2 persones = 2 connexions.  
Analistes: 3 persones = 3 connexions.  



## Requisito 3: Memoria
Asignado 2 GB al contenedor postgreSQL.

### Cálculo de memoria

**Shared buffers**: 512 MB

**maintenance_work_mem**: 128 MB

**work_mem**: 12 MB

|Parámetro  |Tipo memoria  |Valor  |Justificación  |
|---------|---------|---------|---------|
|Sistema operativo|SO|512 MB|Margen reservado para el kernel Linux del contenedor y procesos en segundo plano del SO.|
|shared_buffers|Memoria compartida|512 MB |25% de la RAM total (estándar óptimo en PostgreSQL). Espacio compartido para almacenar páginas de datos en caché.|
|maintenance_work_mem|Memoria por operación puntual de mantenimiento|128 MB|Memoria para mantenimientos (VACUUM, creación de índices). No compite con las consultas regulares.|
|work_mem|Memoria por operación|12 MB|Memoria máxima por operación de ordenación/agrupación.|

Total peor caso: $512\text{ MB (SO)} + 512\text{ MB (shared)} + 720\text{ MB (work)} + 128\text{ MB} = \mathbf{1872\text{ MB}} < 2048\text{ MB}$.
Se queda un margen de 176 MB libres.
### Salida del servidor
#### Comandos utilizados
docker exec -i empresa-db psql -U postgres -c "SHOW shared_buffers;"

docker exec -i empresa-db psql -U postgres -c "SHOW work_mem;"

docker exec -i empresa-db psql -U postgres -c "SHOW maintenance_work_mem;"

docker exec -i empresa-db psql -U postgres -c "SHOW max_connections;"

#### Verificación
```bash
docker exec -i empresa-db psql -U alumno -c "SELECT name, current_setting(name) AS valor_actiu FROM pg_settings WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem', 'max_connections');"
```
Salida obtenida:
```bash
         name         | valor_actiu 
----------------------+-------------
 maintenance_work_mem | 128MB
 max_connections      | 60
 shared_buffers       | 512MB
 work_mem             | 12MB
```
![Salida de los comandos](img/3.output.png)


## Requisito 4: Conexiones
El servidor debe admitir todas las conexiones necesarias para el ERP y el personal, pero no más de las necesarias.

En el paso anterior, junto al cálculo de memoria, ya calculamos las conexiones necesarias. 

- ERP: 3 instancias $\times$ 15 conexiones = 45 conexiones.
- RRHH: 2 personas = 2 conexiones.   
- Analistas: 3 personas = 3 conexiones.   
- Total nominal concurrente: 50 conexiones.   
- Total configurado en max_connections: 60 conexiones (dejando 10 slots de reserva y margen técnico para el superusuario/mantenimiento).   

### Prueba de conexión límite
Se prueba utilizando el comando pgbench para simular varias conexiones simultáneas. Hay que crear tablas de prueba para que funcione pgbench. 

#### 1. Crear las tablas de prueba de pgbench
docker exec -i -e PGPASSWORD=alumno cliente_interno pgbench -i -U alumno -h 172.30.0.10 postgres

#### 2. Lanzar la saturación de 65 conexiones
```bash
docker exec -i -e PGPASSWORD=alumno cliente_interno pgbench -U alumno -h 172.30.0.10 -c 65 -j 65 -T 2 postgres
```
![Salida de los comandos](img/4.conexiones_invalidas.png)
![Salida de los comandos](img/4.conexiones_validas.png)


## Requisito 5: Almacenamiento
Crear un tablespace para ERP y otro para los empleados en volúmenes separados. 
Se mantienen los datos cuando se reinicia el servidor. 
Se han definido dos volúmenes independientes en Docker (`vol_erp` montado en `/mnt/vol_erp` y `vol_empleados` montado en `/mnt/vol_empl`) para aislar físicamente el crecimiento masivo de datos del ERP respecto a los datos estables de RRHH.
### 1. Preparación de permisos y creación de tablespaces
PostgreSQL requiere que los directorios físicos pertenezcan al usuario de sistema `postgres` con permisos `700`:
```bash
docker exec -i -u root empresa-db bash -c "chown -R postgres:postgres /mnt/vol_erp /mnt/vol_empl && chmod 700 /mnt/vol_erp /mnt/vol_empl"

docker exec -i empresa-db psql -U alumno -d postgres < sql/01_tablespaces.sql
```
### 2. Evidencia de ubicación física
Consulta del catálogo pg_tablespace
```bash
docker exec -i empresa-db psql -U alumno -d postgres -c "SELECT spcname AS tablespace, pg_tablespace_location(oid) AS ruta_fisica FROM pg_tablespace WHERE spcname IN ('ts_erp', 'ts_empleados');"
```
Salida obtenida:
```
  tablespace  |  ruta_fisica  
--------------+---------------
 ts_erp       | /mnt/vol_erp
 ts_empleados | /mnt/vol_empl
```

##6: Trazabilidad
Si alguien intenta conectarse sin permiso, debe quedar constancia, aunque el contenedor se destruya.
Se guarda en un almacenamiento persistente en `vol_logs:/var/log/postgresql`