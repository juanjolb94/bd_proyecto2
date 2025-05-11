CREATE DATABASE  IF NOT EXISTS `proyecto2` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `proyecto2`;
-- MySQL dump 10.13  Distrib 8.0.29, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: proyecto2
-- ------------------------------------------------------
-- Server version	8.0.29

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `categoria_producto`
--

DROP TABLE IF EXISTS `categoria_producto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categoria_producto` (
  `id_categoria` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) NOT NULL,
  `estado` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id_categoria`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categoria_producto`
--

LOCK TABLES `categoria_producto` WRITE;
/*!40000 ALTER TABLE `categoria_producto` DISABLE KEYS */;
INSERT INTO `categoria_producto` VALUES (1,'Bebidas',1),(2,'Comidas',1),(3,'Otros',1);
/*!40000 ALTER TABLE `categoria_producto` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `compras_cabecera`
--

DROP TABLE IF EXISTS `compras_cabecera`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `compras_cabecera` (
  `id_compra` int NOT NULL AUTO_INCREMENT,
  `fecha_compra` date NOT NULL,
  `id_proveedor` int NOT NULL,
  `tipo_documento` varchar(50) NOT NULL,
  `nro_documento` varchar(50) NOT NULL,
  `timbrado` varchar(50) DEFAULT NULL,
  `fecha_vencimiento` date DEFAULT NULL,
  `condicion` varchar(20) NOT NULL,
  `subtotal` decimal(12,2) NOT NULL,
  `total_iva5` decimal(12,2) NOT NULL DEFAULT '0.00',
  `total_iva10` decimal(12,2) NOT NULL DEFAULT '0.00',
  `total_iva` decimal(12,2) NOT NULL DEFAULT '0.00',
  `total` decimal(12,2) NOT NULL,
  `nro_planilla` varchar(50) DEFAULT NULL,
  `observaciones` text,
  `estado` tinyint(1) DEFAULT '1',
  `fecha_registro` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_compra`),
  KEY `id_proveedor` (`id_proveedor`),
  CONSTRAINT `compras_cabecera_ibfk_1` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `compras_cabecera`
--

LOCK TABLES `compras_cabecera` WRITE;
/*!40000 ALTER TABLE `compras_cabecera` DISABLE KEYS */;
/*!40000 ALTER TABLE `compras_cabecera` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `compras_detalle`
--

DROP TABLE IF EXISTS `compras_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `compras_detalle` (
  `id_compra` int DEFAULT NULL,
  `id_detalle` int NOT NULL AUTO_INCREMENT,
  `id_producto` int DEFAULT NULL,
  `cod_barra` varchar(50) DEFAULT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `cantidad` decimal(10,2) NOT NULL,
  `unidad_medida` varchar(10) NOT NULL,
  `unidades_por_empaque` int DEFAULT '1',
  `precio_unitario` decimal(12,2) NOT NULL,
  `descuento` decimal(12,2) DEFAULT '0.00',
  `precio_final` decimal(12,2) NOT NULL,
  `porcentaje_iva` decimal(5,2) NOT NULL,
  `subtotal` decimal(12,2) NOT NULL,
  PRIMARY KEY (`id_detalle`),
  KEY `idx_compra` (`id_compra`),
  KEY `fk_producto_detalle` (`id_producto`,`cod_barra`),
  CONSTRAINT `compras_detalle_ibfk_1` FOREIGN KEY (`id_compra`) REFERENCES `compras_cabecera` (`id_compra`),
  CONSTRAINT `fk_producto_detalle` FOREIGN KEY (`id_producto`, `cod_barra`) REFERENCES `productos_detalle` (`id_producto`, `cod_barra`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `compras_detalle`
--

LOCK TABLES `compras_detalle` WRITE;
/*!40000 ALTER TABLE `compras_detalle` DISABLE KEYS */;
/*!40000 ALTER TABLE `compras_detalle` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `after_compras_detalle_insert` AFTER INSERT ON `compras_detalle` FOR EACH ROW BEGIN
    CALL actualizar_stock_compra(
        NEW.id_producto, 
        NEW.cod_barra, 
        NEW.cantidad, 
        NEW.unidades_por_empaque, 
        NEW.precio_unitario
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `marca_producto`
--

DROP TABLE IF EXISTS `marca_producto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `marca_producto` (
  `id_marca` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) NOT NULL,
  `estado` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id_marca`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `marca_producto`
--

LOCK TABLES `marca_producto` WRITE;
/*!40000 ALTER TABLE `marca_producto` DISABLE KEYS */;
INSERT INTO `marca_producto` VALUES (1,'Coca-Cola',1),(2,'Pepsi',1),(3,'Pilsen',1),(4,'Munich',1),(5,'Heineken',1),(6,'Corona',1),(7,'Stella Artois',1),(8,'Paulaner',1),(9,'Patagonia',1);
/*!40000 ALTER TABLE `marca_producto` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `personas`
--

DROP TABLE IF EXISTS `personas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `personas` (
  `id_persona` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `ci` varchar(20) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL,
  `fecha_nac` date NOT NULL,
  `activo` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id_persona`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personas`
--

LOCK TABLES `personas` WRITE;
/*!40000 ALTER TABLE `personas` DISABLE KEYS */;
INSERT INTO `personas` VALUES (1,'Juan Manuel','Lopez Roa','1124706','0971456189','','1971-06-24',1),(2,'Evelina Patricia','Bernal Gamarra','1823306','0971440753','evelina-bernal11@hotmail.com','1973-07-11',1),(3,'Juan Jose','Lopez Bernal','3818632','0972541782','','1994-09-24',1),(4,'PARAGUAY REFRESCOS S.A.','','80003400-7','021-9591661','info@koandina.com','2022-08-17',1),(5,'EMCESA S.A.C.I.','','80006251-5','021-585002','','2023-03-17',1),(6,'CERVEPAR S.A.','','80086846-3','021-5886003','atencionalcliente@cervepar.com.py','2021-01-08',0);
/*!40000 ALTER TABLE `personas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos_cabecera`
--

DROP TABLE IF EXISTS `productos_cabecera`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos_cabecera` (
  `id_producto` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `id_categoria` int NOT NULL,
  `id_marca` int DEFAULT NULL,
  `iva` decimal(5,2) DEFAULT '10.00' COMMENT 'IVA Paraguay 10%',
  `estado` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id_producto`),
  KEY `id_categoria` (`id_categoria`),
  KEY `id_marca` (`id_marca`),
  CONSTRAINT `productos_cabecera_ibfk_1` FOREIGN KEY (`id_categoria`) REFERENCES `categoria_producto` (`id_categoria`),
  CONSTRAINT `productos_cabecera_ibfk_2` FOREIGN KEY (`id_marca`) REFERENCES `marca_producto` (`id_marca`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos_cabecera`
--

LOCK TABLES `productos_cabecera` WRITE;
/*!40000 ALTER TABLE `productos_cabecera` DISABLE KEYS */;
INSERT INTO `productos_cabecera` VALUES (1,'Coca-Cola',1,1,10.00,1),(2,'Sprite',1,1,10.00,1),(3,'Fanta',1,1,10.00,1),(4,'Pilsen',1,3,10.00,1),(5,'Munich',1,4,10.00,1),(6,'Heineken',1,5,10.00,1),(7,'Powerade',1,1,10.00,1),(8,'Monster',1,1,10.00,1),(9,'Patagonia',1,9,10.00,1),(10,'Stella Artois',1,7,10.00,1);
/*!40000 ALTER TABLE `productos_cabecera` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos_detalle`
--

DROP TABLE IF EXISTS `productos_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos_detalle` (
  `id_detalle` int NOT NULL AUTO_INCREMENT,
  `id_producto` int NOT NULL,
  `cod_barra` varchar(50) DEFAULT NULL COMMENT 'Código de barras único',
  `descripcion` varchar(100) NOT NULL COMMENT 'Descripción de la variante',
  `presentacion` enum('LATA','BOTELLA','VASO','PACK','CAJA','BOLSA','OTRO','UNIDAD','PAQUETE','FRASCO','METRO','KILO','LITRO') DEFAULT NULL,
  `estado` tinyint(1) DEFAULT '1' COMMENT '1=Activo, 0=Inactivo',
  `unidad_medida_compra` varchar(10) DEFAULT 'UND',
  `unidad_medida_stock` varchar(10) DEFAULT 'UND',
  `precio_compra` decimal(12,2) DEFAULT '0.00',
  PRIMARY KEY (`id_detalle`),
  UNIQUE KEY `cod_barra` (`cod_barra`),
  UNIQUE KEY `idx_producto_barra` (`id_producto`,`cod_barra`),
  CONSTRAINT `productos_detalle_ibfk_1` FOREIGN KEY (`id_producto`) REFERENCES `productos_cabecera` (`id_producto`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos_detalle`
--

LOCK TABLES `productos_detalle` WRITE;
/*!40000 ALTER TABLE `productos_detalle` DISABLE KEYS */;
INSERT INTO `productos_detalle` VALUES (1,1,'7790040320015','Botella 500ml','BOTELLA',1,'UND','UND',0.00),(2,1,'7790040320022','Lata 355ml','LATA',1,'UND','UND',0.00),(3,2,'7790040320039','Botella 500ml','BOTELLA',1,'UND','UND',0.00),(7,7,'7840058002877','Mountain Blast P500','CAJA',1,'UND','UND',0.00),(8,8,'70847037033','Ultra 473ml','LATA',1,'UND','UND',0.00),(9,1,'7840058009456','Botella 1L DESC','BOTELLA',1,'UND','UND',0.00),(10,5,'7840025110864','Original 970ml RET','BOTELLA',1,'UND','UND',0.00),(11,5,'7840025000127','Ultra 275ml','BOTELLA',1,'UND','UND',0.00),(12,4,'7840050002806','Botella 0.710L','BOTELLA',1,'UND','UND',0.00),(13,9,'7792798002405','Amber OW','BOTELLA',1,'UND','UND',0.00),(14,10,'7891991295239','OW 600ml','BOTELLA',1,'UND','UND',0.00),(16,4,'7840050000376','Barril 30L','UNIDAD',1,'UND','UND',0.00);
/*!40000 ALTER TABLE `productos_detalle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proveedores`
--

DROP TABLE IF EXISTS `proveedores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `proveedores` (
  `id_proveedor` int NOT NULL AUTO_INCREMENT,
  `razon_social` varchar(100) NOT NULL,
  `ruc` varchar(12) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `direccion` varchar(200) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `estado` tinyint(1) DEFAULT '1',
  `id_persona` int DEFAULT NULL,
  PRIMARY KEY (`id_proveedor`),
  UNIQUE KEY `ruc` (`ruc`),
  KEY `fk_proveedores_personas` (`id_persona`),
  CONSTRAINT `fk_proveedores_personas` FOREIGN KEY (`id_persona`) REFERENCES `personas` (`id_persona`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proveedores`
--

LOCK TABLES `proveedores` WRITE;
/*!40000 ALTER TABLE `proveedores` DISABLE KEYS */;
INSERT INTO `proveedores` VALUES (1,'PARAGUAY REFRESCOS S.A.','80003400-7','021-9591661','','info@koandina.com',1,4),(2,'EMCESA','80006251-5','021-585002','','',1,5),(3,'CERVEPAR S.A.','80086846-3','021-5886003','','atencionalcliente@cervepar.com.py',1,6);
/*!40000 ALTER TABLE `proveedores` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id_rol` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `activo` tinyint(1) NOT NULL,
  PRIMARY KEY (`id_rol`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'Administrador',1),(2,'Cajero',0);
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stock`
--

DROP TABLE IF EXISTS `stock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock` (
  `id_producto` int NOT NULL,
  `cod_barra` varchar(50) NOT NULL,
  `cantidad_disponible` decimal(10,2) DEFAULT '0.00',
  `fecha_ultima_actualizacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `costo_promedio` decimal(12,2) DEFAULT '0.00',
  PRIMARY KEY (`id_producto`,`cod_barra`),
  CONSTRAINT `stock_ibfk_1` FOREIGN KEY (`id_producto`, `cod_barra`) REFERENCES `productos_detalle` (`id_producto`, `cod_barra`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stock`
--

LOCK TABLES `stock` WRITE;
/*!40000 ALTER TABLE `stock` DISABLE KEYS */;
/*!40000 ALTER TABLE `stock` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `unidades_medida`
--

DROP TABLE IF EXISTS `unidades_medida`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `unidades_medida` (
  `id_unidad_medida` int NOT NULL AUTO_INCREMENT,
  `codigo` varchar(10) NOT NULL,
  `descripcion` varchar(50) NOT NULL,
  `factor_conversion` decimal(10,2) NOT NULL DEFAULT '1.00',
  `activo` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id_unidad_medida`),
  UNIQUE KEY `codigo` (`codigo`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `unidades_medida`
--

LOCK TABLES `unidades_medida` WRITE;
/*!40000 ALTER TABLE `unidades_medida` DISABLE KEYS */;
INSERT INTO `unidades_medida` VALUES (1,'UND','Unidad',1.00,1),(2,'PAC','Pack',12.00,1),(3,'CAJ','Caja',12.00,1),(4,'BAR','Barril',1.00,1),(5,'DOC','Docena',12.00,1);
/*!40000 ALTER TABLE `unidades_medida` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `UsuarioID` int NOT NULL AUTO_INCREMENT,
  `PersonaID` int NOT NULL,
  `RolID` int NOT NULL,
  `NombreUsuario` varchar(50) NOT NULL,
  `Contraseña` varchar(255) NOT NULL,
  `Activo` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`UsuarioID`),
  UNIQUE KEY `NombreUsuario` (`NombreUsuario`),
  KEY `PersonaID` (`PersonaID`),
  KEY `RolID` (`RolID`),
  CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`PersonaID`) REFERENCES `personas` (`id_persona`),
  CONSTRAINT `usuarios_ibfk_2` FOREIGN KEY (`RolID`) REFERENCES `roles` (`id_rol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'proyecto2'
--

--
-- Dumping routines for database 'proyecto2'
--
/*!50003 DROP PROCEDURE IF EXISTS `actualizar_stock_compra` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_stock_compra`(
    IN p_id_producto INT,
    IN p_cod_barra VARCHAR(50),
    IN p_cantidad DECIMAL(10,2),
    IN p_unidades_por_empaque INT,
    IN p_precio_compra DECIMAL(12,2)
)
BEGIN
    DECLARE v_stock_actual DECIMAL(10,2);
    DECLARE v_costo_actual DECIMAL(12,2);
    DECLARE v_cantidad_total DECIMAL(10,2);
    
    -- Calcular cantidad total en unidades de stock
    SET v_cantidad_total = p_cantidad * p_unidades_por_empaque;
    
    -- Verificar si existe el registro en stock
    SELECT cantidad_disponible, costo_promedio INTO v_stock_actual, v_costo_actual
    FROM stock 
    WHERE id_producto = p_id_producto AND cod_barra = p_cod_barra;
    
    IF v_stock_actual IS NULL THEN
        -- Si no existe, insertar nuevo registro
        INSERT INTO stock (id_producto, cod_barra, cantidad_disponible, costo_promedio)
        VALUES (p_id_producto, p_cod_barra, v_cantidad_total, p_precio_compra);
    ELSE
        -- Si existe, actualizar el stock y calcular costo promedio
        UPDATE stock 
        SET cantidad_disponible = v_stock_actual + v_cantidad_total,
            costo_promedio = ((v_stock_actual * v_costo_actual) + (v_cantidad_total * p_precio_compra)) / 
                             (v_stock_actual + v_cantidad_total),
            fecha_ultima_actualizacion = CURRENT_TIMESTAMP
        WHERE id_producto = p_id_producto AND cod_barra = p_cod_barra;
    END IF;
    
    -- Actualizar precio de compra en productos_detalle
    UPDATE productos_detalle
    SET precio_compra = p_precio_compra
    WHERE id_producto = p_id_producto AND cod_barra = p_cod_barra;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-05-11 13:28:56
