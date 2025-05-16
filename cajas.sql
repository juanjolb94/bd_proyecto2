-- Script SQL para crear la tabla de cajas (Versión corregida)
CREATE TABLE IF NOT EXISTS cajas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha_apertura TIMESTAMP NOT NULL,
    monto_apertura BIGINT NOT NULL,
    usuario_apertura VARCHAR(50) NOT NULL,
    fecha_cierre TIMESTAMP NULL,
    monto_cierre BIGINT NULL,
    monto_ventas BIGINT NULL,
    monto_gastos BIGINT NULL,
    diferencia BIGINT NULL,
    usuario_cierre VARCHAR(50) NULL,
    estado_abierto BOOLEAN NOT NULL DEFAULT TRUE,
    observaciones TEXT NULL,
    CONSTRAINT chk_montos CHECK (monto_apertura >= 0 AND (monto_cierre IS NULL OR monto_cierre >= 0) AND 
                               (monto_ventas IS NULL OR monto_ventas >= 0) AND 
                               (monto_gastos IS NULL OR monto_gastos >= 0))
);

-- Índices para optimizar consultas
CREATE INDEX idx_cajas_estado ON cajas (estado_abierto);
CREATE INDEX idx_cajas_fechas ON cajas (fecha_apertura, fecha_cierre);

-- Tabla de detalle para registrar arqueo de billetes y monedas
CREATE TABLE IF NOT EXISTS caja_arqueo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_caja INT NOT NULL,
    denominacion INT NOT NULL,
    cantidad INT NOT NULL,
    es_billete BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (id_caja) REFERENCES cajas(id) ON DELETE CASCADE,
    CONSTRAINT chk_cantidad CHECK (cantidad >= 0)
);

-- Crear tabla auxiliar para gastos
CREATE TABLE IF NOT EXISTS gastos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    monto BIGINT NOT NULL,
    concepto VARCHAR(255) NOT NULL,
    id_caja INT NULL,
    usuario VARCHAR(50) NOT NULL,
    anulado BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (id_caja) REFERENCES cajas(id) ON DELETE SET NULL,
    CONSTRAINT chk_monto_gasto CHECK (monto > 0)
);

-- Función para verificar si hay una caja abierta (Corregida)
DELIMITER $$
CREATE FUNCTION hay_caja_abierta() 
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE cuenta INT;
    SELECT COUNT(*) INTO cuenta FROM cajas WHERE estado_abierto = TRUE;
    RETURN cuenta > 0;
END$$
DELIMITER ;

-- Procedimiento para abrir caja (Corregido)
DELIMITER $$
CREATE PROCEDURE abrir_caja(
    IN p_monto_apertura BIGINT,
    IN p_usuario_apertura VARCHAR(50)
)
MODIFIES SQL DATA
BEGIN
    DECLARE existe_caja_abierta BOOLEAN;
    SET existe_caja_abierta = hay_caja_abierta();
    
    IF existe_caja_abierta THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una caja abierta. Debe cerrar la caja actual antes de abrir una nueva.';
    ELSE
        INSERT INTO cajas (fecha_apertura, monto_apertura, usuario_apertura, estado_abierto)
        VALUES (NOW(), p_monto_apertura, p_usuario_apertura, TRUE);
    END IF;
END$$
DELIMITER ;

-- Procedimiento para cerrar caja (Corregido)
DELIMITER $$
CREATE PROCEDURE cerrar_caja(
    IN p_id_caja INT,
    IN p_monto_cierre BIGINT,
    IN p_usuario_cierre VARCHAR(50),
    IN p_observaciones TEXT
)
MODIFIES SQL DATA
BEGIN
    DECLARE v_monto_apertura BIGINT;
    DECLARE v_monto_ventas BIGINT;
    DECLARE v_monto_gastos BIGINT;
    DECLARE v_diferencia BIGINT;
    DECLARE v_estado_abierto BOOLEAN;
    
    -- Verificar que la caja exista y esté abierta
    SELECT monto_apertura, estado_abierto INTO v_monto_apertura, v_estado_abierto
    FROM cajas WHERE id = p_id_caja;
    
    IF v_estado_abierto IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La caja especificada no existe.';
    ELSEIF v_estado_abierto = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La caja ya está cerrada.';
    ELSE
        -- Calcular total de ventas
        SELECT COALESCE(SUM(total), 0) INTO v_monto_ventas
        FROM ventas 
        WHERE fecha >= (SELECT fecha_apertura FROM cajas WHERE id = p_id_caja)
        AND fecha <= NOW()
        AND anulado = FALSE;
        
        -- Calcular total de gastos
        SELECT COALESCE(SUM(monto), 0) INTO v_monto_gastos
        FROM gastos 
        WHERE fecha >= (SELECT fecha_apertura FROM cajas WHERE id = p_id_caja)
        AND fecha <= NOW()
        AND anulado = FALSE;
        
        -- Calcular diferencia
        SET v_diferencia = p_monto_cierre - (v_monto_apertura + v_monto_ventas - v_monto_gastos);
        
        -- Actualizar la caja
        UPDATE cajas SET
            fecha_cierre = NOW(),
            monto_cierre = p_monto_cierre,
            monto_ventas = v_monto_ventas,
            monto_gastos = v_monto_gastos,
            diferencia = v_diferencia,
            usuario_cierre = p_usuario_cierre,
            estado_abierto = FALSE,
            observaciones = p_observaciones
        WHERE id = p_id_caja;
    END IF;
END$$
DELIMITER ;

-- Procedimiento para registrar arqueo de caja (Corregido)
DELIMITER $$
CREATE PROCEDURE registrar_arqueo(
    IN p_id_caja INT,
    IN p_denominacion INT,
    IN p_cantidad INT,
    IN p_es_billete BOOLEAN
)
MODIFIES SQL DATA
BEGIN
    -- Verificar si ya existe un registro para esta denominación
    DECLARE v_id_existente INT;
    
    SELECT id INTO v_id_existente
    FROM caja_arqueo
    WHERE id_caja = p_id_caja AND denominacion = p_denominacion AND es_billete = p_es_billete;
    
    IF v_id_existente IS NULL THEN
        -- Insertar nuevo registro
        INSERT INTO caja_arqueo (id_caja, denominacion, cantidad, es_billete)
        VALUES (p_id_caja, p_denominacion, p_cantidad, p_es_billete);
    ELSE
        -- Actualizar registro existente
        UPDATE caja_arqueo
        SET cantidad = p_cantidad
        WHERE id = v_id_existente;
    END IF;
END$$
DELIMITER ;

-- Procedimiento para eliminar todos los arqueos de una caja (Nuevo)
DELIMITER $$
CREATE PROCEDURE limpiar_arqueos_caja(
    IN p_id_caja INT
)
MODIFIES SQL DATA
BEGIN
    DELETE FROM caja_arqueo WHERE id_caja = p_id_caja;
END$$
DELIMITER ;

-- Procedimiento para obtener el resumen de caja (Nuevo)
DELIMITER $$
CREATE PROCEDURE obtener_resumen_caja(
    IN p_id_caja INT
)
READS SQL DATA
BEGIN
    SELECT 
        c.id, 
        c.fecha_apertura, 
        c.monto_apertura, 
        c.usuario_apertura,
        c.fecha_cierre, 
        c.monto_cierre, 
        c.monto_ventas, 
        c.monto_gastos, 
        c.diferencia,
        c.usuario_cierre, 
        c.estado_abierto,
        
        -- Calcular valores de arqueo
        (SELECT SUM(denominacion * cantidad) FROM caja_arqueo 
         WHERE id_caja = c.id AND es_billete = TRUE) AS total_billetes,
         
        (SELECT SUM(denominacion * cantidad) FROM caja_arqueo 
         WHERE id_caja = c.id AND es_billete = FALSE) AS total_monedas,
         
        (SELECT COUNT(*) FROM caja_arqueo WHERE id_caja = c.id) AS cantidad_denominaciones
    FROM 
        cajas c
    WHERE 
        c.id = p_id_caja;
END$$
DELIMITER ;

-- Vista para consulta rápida de cajas activas
CREATE OR REPLACE VIEW v_cajas_activas AS
SELECT 
    id,
    fecha_apertura,
    monto_apertura,
    usuario_apertura,
    TIMESTAMPDIFF(HOUR, fecha_apertura, NOW()) AS horas_abierta,
    estado_abierto
FROM 
    cajas
WHERE 
    estado_abierto = TRUE;

-- Consulta de rendimiento por días
CREATE OR REPLACE VIEW v_rendimiento_cajas AS
SELECT 
    DATE(fecha_apertura) AS fecha,
    COUNT(*) AS cantidad_cajas,
    SUM(monto_apertura) AS total_apertura,
    SUM(monto_ventas) AS total_ventas,
    SUM(monto_gastos) AS total_gastos,
    SUM(monto_ventas - monto_gastos) AS rendimiento_neto,
    SUM(ABS(diferencia)) AS total_diferencias,
    SUM(IF(diferencia > 0, diferencia, 0)) AS total_sobrantes,
    SUM(IF(diferencia < 0, ABS(diferencia), 0)) AS total_faltantes
FROM 
    cajas
WHERE 
    estado_abierto = FALSE
GROUP BY 
    DATE(fecha_apertura)
ORDER BY 
    fecha DESC;