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
|7. Ampliación     |         |         |

Utilizado postgres 16 por ser una versión estable y no usar una versión latest. 
Redes:
      ud1_interna:
        ipv4_address: 172.30.0.10/24
      ud1_visitantes:
        ipv4_address: 172.31.0.10/24
    Asignadas la .10 ya que las primeras IPs las suele utilizar docker.
    

credenciales en .env ocultado por .gitignore

se utiliza como clientes la misma imagen de postgres para evitar tener que instalar en otras imagenes el psql, ya que en postgres ya viene instalado. 


Se utiliza entrypoint: ["sleep", "infinity"] para evitar que inicializen su base de datos

Se crea además un volumen de logs apuntando a /var/logs/postgresql para cumplir con el apartado 6

Limite conexiones de 60.

ERP: 3 instàncies × 15 connexions cadascuna = 45 connexions.   
Personal de RRHH: 2 persones = 2 connexions.  
Analistes: 3 persones = 3 connexions.  
