-- Tabla de cabecera de listas de precios
CREATE TABLE precio_cabecera (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha_creacion DATE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    moneda VARCHAR (100) NOT NULL
);

-- Tabla de detalle de precios por producto y lista
CREATE TABLE precio_detalle (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_precio_cabecera INT NOT NULL,
    codigo_barra VARCHAR(50) NOT NULL,
    precio INT NOT NULL,
    fecha_vigencia DATE NOT NULL,
    FOREIGN KEY (id_precio_cabecera) REFERENCES precio_cabecera(id),
    FOREIGN KEY (codigo_barra) REFERENCES productos_detalle(cod_barra)
);