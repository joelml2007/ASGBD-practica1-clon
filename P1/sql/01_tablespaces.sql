-- Creación de los espacios de almacenamiento físicos (Requisito 5)
CREATE TABLESPACE ts_erp LOCATION '/mnt/vol_erp';
CREATE TABLESPACE ts_empleados LOCATION '/mnt/vol_empl';

-- Tablas iniciales de prueba en cada tablespace para demostrar persistencia
CREATE TABLE IF NOT EXISTS pedidos_erp (
    id SERIAL PRIMARY KEY,
    concepto VARCHAR(100) NOT NULL,
    importe NUMERIC(10,2) NOT NULL
) TABLESPACE ts_erp;

CREATE TABLE IF NOT EXISTS plantilla_empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    puesto VARCHAR(50) NOT NULL,
    salario NUMERIC(10,2) NOT NULL
) TABLESPACE ts_empleados;

-- Datos iniciales
INSERT INTO pedidos_erp (concepto, importe) VALUES ('Servidor Rack Dell', 3450.00);
INSERT INTO plantilla_empleados (nombre, puesto, salario) VALUES ('Laura Gómez', 'Técnica RRHH', 28000.00);