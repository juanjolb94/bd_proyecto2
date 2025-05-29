-- Crear tabla clientes
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    ci_ruc VARCHAR(20) NOT NULL,
    telefono VARCHAR(20),
    direccion TEXT,
    email VARCHAR(100),
    estado BOOLEAN DEFAULT TRUE,
    id_persona INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Clave foránea hacia personas
    FOREIGN KEY (id_persona) REFERENCES personas(id_persona) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    -- Índices para mejorar rendimiento
    INDEX idx_clientes_ci_ruc (ci_ruc),
    INDEX idx_clientes_nombre (nombre),
    INDEX idx_clientes_estado (estado),
    INDEX idx_clientes_persona (id_persona),
    
    -- Constraint para asegurar unicidad del cliente por persona
    UNIQUE KEY uk_cliente_persona (id_persona)
);