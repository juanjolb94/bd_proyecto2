DELIMITER $$

-- Primero eliminar el procedimiento si existe
DROP PROCEDURE IF EXISTS `cerrar_caja` $$

-- Luego crear el nuevo procedimiento
CREATE PROCEDURE `cerrar_caja`(
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
    
    -- Iniciamos una transacción para mantener la consistencia
    START TRANSACTION;
    
    -- Verificar que la caja exista y esté abierta (FOR UPDATE bloquea la fila)
    SELECT monto_apertura, estado_abierto INTO v_monto_apertura, v_estado_abierto
    FROM cajas WHERE id = p_id_caja FOR UPDATE;
    
    IF v_estado_abierto IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La caja especificada no existe.';
        ROLLBACK;
    ELSEIF v_estado_abierto = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La caja ya está cerrada.';
        ROLLBACK;
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
        
        -- Confirmar los cambios
        COMMIT;
    END IF;
END$$

DELIMITER ;