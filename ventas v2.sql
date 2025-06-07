-- SCRIPT FINAL CORREGIDO - ADAPTADO A TU ESTRUCTURA REAL COMPLETA
-- ===============================================================

-- Tu estructura real:
-- clientes: id_cliente, nombre, ci_ruc, telefono, direccion, email, estado, id_persona, created_at, updated_at
-- usuarios: UsuarioID, PersonaID, RolID, NombreUsuario, Contraseña, Activo

-- 1. ELIMINAR ELEMENTOS ANTERIORES SI EXISTEN
-- -------------------------------------------

DROP PROCEDURE IF EXISTS AddColumnIfNotExists;
DROP PROCEDURE IF EXISTS CreateIndexIfNotExists;
DROP PROCEDURE IF EXISTS CreateTableIfNotExists;
DROP FUNCTION IF EXISTS fn_generar_numero_factura;
DROP PROCEDURE IF EXISTS sp_anular_venta;
DROP VIEW IF EXISTS v_ventas_completas;
DROP VIEW IF EXISTS v_productos_mas_vendidos;
DROP TRIGGER IF EXISTS tr_actualizar_totales_venta;
DROP TRIGGER IF EXISTS tr_actualizar_totales_venta_insert;
DROP TRIGGER IF EXISTS tr_actualizar_totales_venta_update;
DROP TRIGGER IF EXISTS tr_actualizar_totales_venta_delete;
DROP TRIGGER IF EXISTS tr_ventas_historico_update;

-- 2. CREAR PROCEDIMIENTOS AUXILIARES
-- ----------------------------------

DELIMITER $$

CREATE PROCEDURE AddColumnIfNotExists(
    IN p_table_name VARCHAR(64),
    IN p_column_name VARCHAR(64),
    IN p_column_definition TEXT
)
BEGIN
    DECLARE column_count INT DEFAULT 0;
    
    SELECT COUNT(*) INTO column_count
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = p_table_name
    AND COLUMN_NAME = p_column_name;
    
    IF column_count = 0 THEN
        SET @sql = CONCAT('ALTER TABLE ', p_table_name, ' ADD COLUMN ', p_column_name, ' ', p_column_definition);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('✓ Columna ', p_column_name, ' agregada a ', p_table_name) AS resultado;
    ELSE
        SELECT CONCAT('- Columna ', p_column_name, ' ya existe en ', p_table_name) AS resultado;
    END IF;
END$$

CREATE PROCEDURE CreateIndexIfNotExists(
    IN p_table_name VARCHAR(64),
    IN p_index_name VARCHAR(64),
    IN p_columns TEXT
)
BEGIN
    DECLARE index_count INT DEFAULT 0;
    
    SELECT COUNT(*) INTO index_count
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = p_table_name
    AND INDEX_NAME = p_index_name;
    
    IF index_count = 0 THEN
        SET @sql = CONCAT('CREATE INDEX ', p_index_name, ' ON ', p_table_name, ' (', p_columns, ')');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('✓ Índice ', p_index_name, ' creado en ', p_table_name) AS resultado;
    ELSE
        SELECT CONCAT('- Índice ', p_index_name, ' ya existe en ', p_table_name) AS resultado;
    END IF;
END$$

CREATE PROCEDURE CreateTableIfNotExists(
    IN p_table_name VARCHAR(64),
    IN p_table_definition TEXT
)
BEGIN
    DECLARE table_count INT DEFAULT 0;
    
    SELECT COUNT(*) INTO table_count
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = p_table_name;
    
    IF table_count = 0 THEN
        SET @sql = CONCAT('CREATE TABLE ', p_table_name, ' (', p_table_definition, ')');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('✓ Tabla ', p_table_name, ' creada exitosamente') AS resultado;
    ELSE
        SELECT CONCAT('- Tabla ', p_table_name, ' ya existe') AS resultado;
    END IF;
END$$

DELIMITER ;

-- 3. AGREGAR COLUMNAS A LA TABLA "ventas"
-- ---------------------------------------

SELECT '=== AGREGANDO COLUMNAS A TABLA VENTAS ===' AS '';

CALL AddColumnIfNotExists('ventas', 'created_at', 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP');
CALL AddColumnIfNotExists('ventas', 'updated_at', 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP');
CALL AddColumnIfNotExists('ventas', 'metodo_pago', "ENUM('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'CHEQUE', 'MIXTO') DEFAULT 'EFECTIVO'");
CALL AddColumnIfNotExists('ventas', 'descuento_porcentaje', 'DECIMAL(5,2) DEFAULT 0.00');
CALL AddColumnIfNotExists('ventas', 'descuento_monto', 'INT DEFAULT 0');
CALL AddColumnIfNotExists('ventas', 'subtotal', 'INT DEFAULT 0');
CALL AddColumnIfNotExists('ventas', 'impuesto_total', 'INT DEFAULT 0');
CALL AddColumnIfNotExists('ventas', 'numero_factura', 'VARCHAR(50)');
CALL AddColumnIfNotExists('ventas', 'tipo_venta', "ENUM('CONTADO', 'CREDITO') DEFAULT 'CONTADO'");
CALL AddColumnIfNotExists('ventas', 'estado', "ENUM('PENDIENTE', 'PAGADA', 'ANULADA', 'CREDITO') DEFAULT 'PENDIENTE'");

-- 4. AGREGAR COLUMNAS A LA TABLA "ventas_detalle"
-- -----------------------------------------------

SELECT '=== AGREGANDO COLUMNAS A TABLA VENTAS_DETALLE ===' AS '';

CALL AddColumnIfNotExists('ventas_detalle', 'descripcion_producto', 'VARCHAR(255)');
CALL AddColumnIfNotExists('ventas_detalle', 'costo_unitario', 'INT DEFAULT 0');
CALL AddColumnIfNotExists('ventas_detalle', 'descuento_porcentaje', 'DECIMAL(5,2) DEFAULT 0.00');
CALL AddColumnIfNotExists('ventas_detalle', 'descuento_monto', 'INT DEFAULT 0');
CALL AddColumnIfNotExists('ventas_detalle', 'precio_original', 'INT DEFAULT 0');
CALL AddColumnIfNotExists('ventas_detalle', 'base_imponible', 'INT DEFAULT 0');
CALL AddColumnIfNotExists('ventas_detalle', 'impuesto_monto', 'INT DEFAULT 0');
CALL AddColumnIfNotExists('ventas_detalle', 'impuesto_porcentaje', 'DECIMAL(5,2) DEFAULT 10.00');
CALL AddColumnIfNotExists('ventas_detalle', 'lote', 'VARCHAR(50)');
CALL AddColumnIfNotExists('ventas_detalle', 'fecha_vencimiento', 'DATE');

-- 5. CREAR ÍNDICES
-- ---------------

SELECT '=== CREANDO ÍNDICES ===' AS '';

CALL CreateIndexIfNotExists('ventas', 'idx_ventas_fecha', 'fecha');
CALL CreateIndexIfNotExists('ventas', 'idx_ventas_cliente', 'id_cliente');
CALL CreateIndexIfNotExists('ventas', 'idx_ventas_usuario', 'id_usuario');
CALL CreateIndexIfNotExists('ventas', 'idx_ventas_caja', 'id_caja');
CALL CreateIndexIfNotExists('ventas', 'idx_ventas_numero_factura', 'numero_factura');

CALL CreateIndexIfNotExists('ventas_detalle', 'idx_ventas_detalle_venta', 'id_venta');
CALL CreateIndexIfNotExists('ventas_detalle', 'idx_ventas_detalle_producto', 'id_producto');
CALL CreateIndexIfNotExists('ventas_detalle', 'idx_ventas_detalle_codigo', 'codigo_barra');

-- 6. CREAR NUEVAS TABLAS
-- ----------------------

SELECT '=== CREANDO NUEVAS TABLAS ===' AS '';

CALL CreateTableIfNotExists('ventas_pagos', '
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    metodo_pago ENUM(''EFECTIVO'', ''TARJETA'', ''TRANSFERENCIA'', ''CHEQUE'') NOT NULL,
    monto INT NOT NULL,
    referencia VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_venta) REFERENCES ventas(id) ON DELETE CASCADE,
    INDEX idx_ventas_pagos_venta (id_venta),
    INDEX idx_ventas_pagos_metodo (metodo_pago)
');

CALL CreateTableIfNotExists('ventas_historico', '
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    accion ENUM(''CREADA'', ''MODIFICADA'', ''ANULADA'', ''RESTAURADA'') NOT NULL,
    usuario_id INT,
    fecha_accion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    datos_anteriores TEXT,
    datos_nuevos TEXT,
    motivo TEXT,
    ip_address VARCHAR(45),
    FOREIGN KEY (id_venta) REFERENCES ventas(id) ON DELETE CASCADE,
    INDEX idx_ventas_historico_venta (id_venta),
    INDEX idx_ventas_historico_fecha (fecha_accion)
');

CALL CreateTableIfNotExists('devoluciones', '
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_venta_original INT NOT NULL,
    id_venta_devolucion INT,
    fecha_devolucion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    motivo TEXT NOT NULL,
    monto_devuelto INT NOT NULL,
    usuario_autoriza INT,
    estado ENUM(''PENDIENTE'', ''APROBADA'', ''RECHAZADA'') DEFAULT ''PENDIENTE'',
    observaciones TEXT,
    FOREIGN KEY (id_venta_original) REFERENCES ventas(id),
    INDEX idx_devoluciones_venta_original (id_venta_original),
    INDEX idx_devoluciones_fecha (fecha_devolucion)
');

CALL CreateTableIfNotExists('devoluciones_detalle', '
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_devolucion INT NOT NULL,
    id_producto INT NOT NULL,
    codigo_barra VARCHAR(50) NOT NULL,
    cantidad_devuelta INT NOT NULL,
    precio_unitario INT NOT NULL,
    subtotal INT NOT NULL,
    motivo_detalle VARCHAR(255),
    FOREIGN KEY (id_devolucion) REFERENCES devoluciones(id) ON DELETE CASCADE,
    INDEX idx_devoluciones_detalle_devolucion (id_devolucion)
');

CALL CreateTableIfNotExists('configuracion_ventas', '
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_parametro VARCHAR(50) UNIQUE NOT NULL,
    valor_parametro VARCHAR(255) NOT NULL,
    descripcion TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
');

-- 7. INSERTAR CONFIGURACIÓN INICIAL
-- ---------------------------------

SELECT '=== INSERTANDO CONFIGURACIÓN INICIAL ===' AS '';

INSERT IGNORE INTO configuracion_ventas (nombre_parametro, valor_parametro, descripcion) VALUES
('SERIE_FACTURA', '001', 'Serie de la factura'),
('NUMERO_FACTURA', '0000001', 'Último número de factura utilizado'),
('PREFIJO_FACTURA', 'FAC-', 'Prefijo para el número de factura'),
('IVA_PORCENTAJE', '10.00', 'Porcentaje de IVA por defecto'),
('PERMITE_DESCUENTOS', 'true', 'Permite aplicar descuentos en las ventas'),
('MAXIMO_DESCUENTO', '50.00', 'Máximo porcentaje de descuento permitido');

SELECT 'Configuración inicial insertada' AS resultado;

-- 8. CREAR VISTAS ADAPTADAS A TU ESTRUCTURA REAL
-- ----------------------------------------------

SELECT '=== CREANDO VISTAS ADAPTADAS A TU ESTRUCTURA REAL ===' AS '';

-- Vista para ventas completas (adaptada a clientes y usuarios reales)
CREATE VIEW v_ventas_completas AS
SELECT 
    v.id,
    v.fecha,
    v.numero_factura,
    v.total,
    COALESCE(v.subtotal, v.total) as subtotal,
    COALESCE(v.impuesto_total, 0) as impuesto_total,
    COALESCE(v.descuento_monto, 0) as descuento_monto,
    COALESCE(v.metodo_pago, 'EFECTIVO') as metodo_pago,
    COALESCE(v.tipo_venta, 'CONTADO') as tipo_venta,
    COALESCE(v.estado, 'PAGADA') as estado,
    v.anulado,
    c.nombre as cliente_nombre,
    c.ci_ruc as cliente_documento,
    c.telefono as cliente_telefono,
    c.direccion as cliente_direccion,
    u.NombreUsuario as usuario_nombre     -- Usando 'NombreUsuario' de tu estructura
FROM ventas v
LEFT JOIN clientes c ON v.id_cliente = c.id_cliente
LEFT JOIN usuarios u ON v.id_usuario = u.UsuarioID;  -- Usando 'UsuarioID' de tu estructura

-- Vista para productos más vendidos
CREATE VIEW v_productos_mas_vendidos AS
SELECT 
    vd.id_producto,
    vd.codigo_barra,
    COALESCE(vd.descripcion_producto, 'Sin descripción') as descripcion_producto,
    SUM(vd.cantidad) as cantidad_total_vendida,
    SUM(vd.subtotal) as monto_total_vendido,
    COUNT(DISTINCT vd.id_venta) as numero_ventas,
    AVG(vd.precio_unitario) as precio_promedio
FROM ventas_detalle vd
INNER JOIN ventas v ON vd.id_venta = v.id
WHERE v.anulado = false
GROUP BY vd.id_producto, vd.codigo_barra, vd.descripcion_producto
ORDER BY cantidad_total_vendida DESC;

-- Vista simplificada para consultas rápidas (sin JOIN a usuarios para evitar problemas)
CREATE VIEW v_ventas_simples AS
SELECT 
    v.id,
    v.fecha,
    v.numero_factura,
    v.total,
    v.anulado,
    c.nombre as cliente_nombre,
    c.ci_ruc as cliente_documento
FROM ventas v
LEFT JOIN clientes c ON v.id_cliente = c.id_cliente;

SELECT 'Vistas creadas exitosamente' AS resultado;

-- 9. CREAR TRIGGERS
-- ----------------

SELECT '=== CREANDO TRIGGERS ===' AS '';

-- Eliminar triggers existentes primero
DROP TRIGGER IF EXISTS tr_actualizar_totales_insert;
DROP TRIGGER IF EXISTS tr_actualizar_totales_update;
DROP TRIGGER IF EXISTS tr_actualizar_totales_delete;
DROP TRIGGER IF EXISTS tr_ventas_historico_update;
DROP TRIGGER IF EXISTS tr_actualizar_totales_venta;
DROP TRIGGER IF EXISTS tr_actualizar_totales_venta_insert;
DROP TRIGGER IF EXISTS tr_actualizar_totales_venta_update;
DROP TRIGGER IF EXISTS tr_actualizar_totales_venta_delete;

DELIMITER $

-- Trigger para actualizar totales cuando se inserta un detalle
CREATE TRIGGER tr_actualizar_totales_insert
AFTER INSERT ON ventas_detalle
FOR EACH ROW
BEGIN
    UPDATE ventas 
    SET subtotal = (
        SELECT COALESCE(SUM(subtotal), 0) 
        FROM ventas_detalle 
        WHERE id_venta = NEW.id_venta
    ),
    impuesto_total = (
        SELECT COALESCE(SUM(COALESCE(impuesto_monto, 0)), 0) 
        FROM ventas_detalle 
        WHERE id_venta = NEW.id_venta
    ),
    total = (
        SELECT COALESCE(SUM(subtotal), 0) 
        FROM ventas_detalle 
        WHERE id_venta = NEW.id_venta
    ) - COALESCE(descuento_monto, 0),
    updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.id_venta;
END$

-- Trigger para actualizar totales cuando se actualiza un detalle
CREATE TRIGGER tr_actualizar_totales_update
AFTER UPDATE ON ventas_detalle
FOR EACH ROW
BEGIN
    UPDATE ventas 
    SET subtotal = (
        SELECT COALESCE(SUM(subtotal), 0) 
        FROM ventas_detalle 
        WHERE id_venta = NEW.id_venta
    ),
    impuesto_total = (
        SELECT COALESCE(SUM(COALESCE(impuesto_monto, 0)), 0) 
        FROM ventas_detalle 
        WHERE id_venta = NEW.id_venta
    ),
    total = (
        SELECT COALESCE(SUM(subtotal), 0) 
        FROM ventas_detalle 
        WHERE id_venta = NEW.id_venta
    ) - COALESCE(descuento_monto, 0),
    updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.id_venta;
END$

-- Trigger para actualizar totales cuando se elimina un detalle
CREATE TRIGGER tr_actualizar_totales_delete
AFTER DELETE ON ventas_detalle
FOR EACH ROW
BEGIN
    UPDATE ventas 
    SET subtotal = (
        SELECT COALESCE(SUM(subtotal), 0) 
        FROM ventas_detalle 
        WHERE id_venta = OLD.id_venta
    ),
    impuesto_total = (
        SELECT COALESCE(SUM(COALESCE(impuesto_monto, 0)), 0) 
        FROM ventas_detalle 
        WHERE id_venta = OLD.id_venta
    ),
    total = (
        SELECT COALESCE(SUM(subtotal), 0) 
        FROM ventas_detalle 
        WHERE id_venta = OLD.id_venta
    ) - COALESCE(descuento_monto, 0),
    updated_at = CURRENT_TIMESTAMP
    WHERE id = OLD.id_venta;
END$

DELIMITER ;

SELECT 'Triggers creados exitosamente' AS resultado;

-- 10. CREAR FUNCIÓN PARA GENERAR NÚMERO DE FACTURA
-- ------------------------------------------------

SELECT '=== CREANDO FUNCIÓN PARA NÚMERO DE FACTURA ===' AS '';

-- Eliminar función existente primero
DROP FUNCTION IF EXISTS fn_generar_numero_factura;

DELIMITER $

CREATE FUNCTION fn_generar_numero_factura() 
RETURNS VARCHAR(50)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_serie VARCHAR(10) DEFAULT '001';
    DECLARE v_numero VARCHAR(20) DEFAULT '0000001';
    DECLARE v_prefijo VARCHAR(10) DEFAULT 'FAC-';
    DECLARE v_numero_completo VARCHAR(50);
    
    -- Obtener valores de configuración
    SELECT valor_parametro INTO v_serie 
    FROM configuracion_ventas 
    WHERE nombre_parametro = 'SERIE_FACTURA' LIMIT 1;
    
    SELECT valor_parametro INTO v_numero 
    FROM configuracion_ventas 
    WHERE nombre_parametro = 'NUMERO_FACTURA' LIMIT 1;
    
    SELECT valor_parametro INTO v_prefijo 
    FROM configuracion_ventas 
    WHERE nombre_parametro = 'PREFIJO_FACTURA' LIMIT 1;
    
    SET v_numero_completo = CONCAT(v_prefijo, v_serie, '-', LPAD(v_numero, 7, '0'));
    
    -- Actualizar el contador
    UPDATE configuracion_ventas 
    SET valor_parametro = LPAD(CAST(v_numero AS UNSIGNED) + 1, 7, '0')
    WHERE nombre_parametro = 'NUMERO_FACTURA';
    
    RETURN v_numero_completo;
END$

DELIMITER ;

SELECT 'Función fn_generar_numero_factura creada' AS resultado;

-- 11. CREAR PROCEDIMIENTO PARA ANULAR VENTAS (ADAPTADO)
-- -----------------------------------------------------

SELECT '=== CREANDO PROCEDIMIENTO PARA ANULAR VENTAS ===' AS '';

-- Eliminar procedimiento existente primero
DROP PROCEDURE IF EXISTS sp_anular_venta;

DELIMITER $

CREATE PROCEDURE sp_anular_venta(
    IN p_id_venta INT,
    IN p_usuario_id INT,
    IN p_motivo TEXT
)
BEGIN
    DECLARE v_anulado BOOLEAN DEFAULT FALSE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Verificar si la venta ya está anulada
    SELECT anulado INTO v_anulado FROM ventas WHERE id = p_id_venta;
    
    IF v_anulado THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta ya está anulada';
    END IF;
    
    -- Restaurar stock de productos (adaptado - sin stock en productos_detalle por ahora)
    -- Como no tienes campo stock en productos_detalle, solo registramos la anulación
    -- TODO: Cuando agregues stock, descomenta las siguientes líneas:
    /*
    UPDATE productos_detalle pd
    INNER JOIN ventas_detalle vd ON pd.id_producto = vd.id_producto AND pd.cod_barra = vd.codigo_barra
    SET pd.stock = pd.stock + vd.cantidad
    WHERE vd.id_venta = p_id_venta;
    */
    
    -- Anular la venta
    UPDATE ventas 
    SET anulado = TRUE, 
        estado = 'ANULADA',
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_id_venta;
    
    -- Registrar en histórico
    INSERT INTO ventas_historico (id_venta, accion, usuario_id, motivo)
    VALUES (p_id_venta, 'ANULADA', p_usuario_id, p_motivo);
    
    COMMIT;
    
    SELECT 'Venta anulada exitosamente' AS resultado;
END$

DELIMITER ;

SELECT 'Procedimiento sp_anular_venta creado' AS resultado;

-- 12. LIMPIAR PROCEDIMIENTOS TEMPORALES
-- -------------------------------------

DROP PROCEDURE AddColumnIfNotExists;
DROP PROCEDURE CreateIndexIfNotExists;
DROP PROCEDURE CreateTableIfNotExists;

-- 13. VERIFICACIÓN FINAL
-- ----------------------

SELECT '=== SCRIPT COMPLETADO EXITOSAMENTE ===' AS '';

-- Mostrar resumen de tablas creadas/modificadas
SELECT 
    TABLE_NAME as 'Tabla',
    TABLE_ROWS as 'Filas',
    CREATE_TIME as 'Creada'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
AND (TABLE_NAME LIKE '%venta%' OR TABLE_NAME LIKE '%devolucion%' OR TABLE_NAME = 'configuracion_ventas')
ORDER BY TABLE_NAME;

-- Verificar configuración
SELECT 'Configuración del sistema:' AS '';
SELECT 
    nombre_parametro as 'Parámetro',
    valor_parametro as 'Valor'
FROM configuracion_ventas
ORDER BY nombre_parametro;

-- Probar las vistas creadas
SELECT 'Probando vista v_ventas_simples (primeros 3 registros):' AS '';
SELECT * FROM v_ventas_simples LIMIT 3;

SELECT 'Estructura final de la tabla ventas:' AS '';
SELECT 
    COLUMN_NAME as 'Columna',
    DATA_TYPE as 'Tipo'
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'ventas'
ORDER BY ORDINAL_POSITION;

SELECT '✓ TODAS LAS MEJORAS APLICADAS CORRECTAMENTE' AS RESULTADO_FINAL;