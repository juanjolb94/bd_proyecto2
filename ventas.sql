-- Crear tabla de ventas
CREATE TABLE IF NOT EXISTS ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total BIGINT NOT NULL,
    id_cliente INT NULL,
    id_usuario INT NOT NULL,
    id_caja INT NULL,
    anulado BOOLEAN NOT NULL DEFAULT FALSE,
    observaciones TEXT NULL,
    CONSTRAINT chk_total_venta CHECK (total > 0),
    FOREIGN KEY (id_caja) REFERENCES cajas(id) ON DELETE SET NULL
);

-- Índices para optimizar consultas en ventas
CREATE INDEX idx_ventas_fecha ON ventas (fecha);
CREATE INDEX idx_ventas_caja ON ventas (id_caja);
CREATE INDEX idx_ventas_anulado ON ventas (anulado);

-- Crear tabla de detalles de venta si aún no existe
CREATE TABLE IF NOT EXISTS ventas_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    codigo_barra VARCHAR(50) NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario BIGINT NOT NULL,
    subtotal BIGINT NOT NULL,
    FOREIGN KEY (id_venta) REFERENCES ventas(id) ON DELETE CASCADE,
    CONSTRAINT chk_cantidad_venta CHECK (cantidad > 0),
    CONSTRAINT chk_precio_venta CHECK (precio_unitario > 0)
);