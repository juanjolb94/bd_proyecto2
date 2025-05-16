CREATE TABLE talonarios (
    id_talonario INT AUTO_INCREMENT PRIMARY KEY,
    numero_timbrado VARCHAR(50) NOT NULL,
    fecha_vencimiento DATETIME NOT NULL,
    factura_desde INT NOT NULL,
    factura_hasta INT NOT NULL,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    tipo_comprobante VARCHAR(50) NOT NULL,
    punto_expedicion VARCHAR(3) NOT NULL,
    establecimiento VARCHAR(3) NOT NULL,
    factura_actual INT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_talonario_estado (estado),
    INDEX idx_talonario_timbrado (numero_timbrado),
    CONSTRAINT chk_factura_rango CHECK (factura_hasta > factura_desde),
    CONSTRAINT chk_factura_actual CHECK (factura_actual >= factura_desde AND factura_actual <= factura_hasta)
);
