CREATE DATABASE  IF NOT EXISTS `proyecto2` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `proyecto2`;
-- MySQL dump 10.13  Distrib 8.0.42, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: proyecto2
-- ------------------------------------------------------
-- Server version	8.0.42

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
-- Table structure for table `ajustes_stock_cabecera`
--

DROP TABLE IF EXISTS `ajustes_stock_cabecera`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ajustes_stock_cabecera` (
  `id_ajuste` int NOT NULL AUTO_INCREMENT,
  `fecha` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `observaciones` text,
  `usuario_id` int NOT NULL,
  `aprobado` tinyint(1) DEFAULT '0' COMMENT '0=Pendiente, 1=Aprobado',
  `estado` tinyint(1) DEFAULT '1' COMMENT '1=Activo, 0=Anulado',
  PRIMARY KEY (`id_ajuste`),
  KEY `idx_ajuste_fecha` (`fecha`),
  KEY `idx_ajuste_usuario` (`usuario_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ajustes_stock_cabecera`
--

LOCK TABLES `ajustes_stock_cabecera` WRITE;
/*!40000 ALTER TABLE `ajustes_stock_cabecera` DISABLE KEYS */;
INSERT INTO `ajustes_stock_cabecera` VALUES (1,'2025-06-21 21:47:16','Carga Inicial',1,0,1);
/*!40000 ALTER TABLE `ajustes_stock_cabecera` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_ajuste_stock_aprobacion` AFTER UPDATE ON `ajustes_stock_cabecera` FOR EACH ROW BEGIN
    -- Solo ejecutar si cambió el estado de aprobación
    IF OLD.aprobado != NEW.aprobado THEN
        
        IF NEW.aprobado = 1 THEN
            -- APROBAR: Aplicar ajustes al stock
            UPDATE stock s
            INNER JOIN ajustes_stock_detalle asd ON s.id_producto = asd.id_producto 
                AND s.cod_barra = asd.cod_barra
            SET s.cantidad_disponible = asd.cantidad_ajuste,
                s.fecha_ultima_actualizacion = NOW()
            WHERE asd.id_ajuste = NEW.id_ajuste;
            
            -- Insertar en stock si no existe el producto
            INSERT INTO stock (id_producto, cod_barra, cantidad_disponible, fecha_ultima_actualizacion, costo_promedio)
            SELECT asd.id_producto, asd.cod_barra, asd.cantidad_ajuste, NOW(), 0.00
            FROM ajustes_stock_detalle asd
            WHERE asd.id_ajuste = NEW.id_ajuste
                AND NOT EXISTS (
                    SELECT 1 FROM stock s 
                    WHERE s.id_producto = asd.id_producto 
                        AND s.cod_barra = asd.cod_barra
                );
        ELSE
            -- DESAPROBAR: Revertir al stock del sistema original
            UPDATE stock s
            INNER JOIN ajustes_stock_detalle asd ON s.id_producto = asd.id_producto 
                AND s.cod_barra = asd.cod_barra
            SET s.cantidad_disponible = asd.cantidad_sistema,
                s.fecha_ultima_actualizacion = NOW()
            WHERE asd.id_ajuste = NEW.id_ajuste;
        END IF;
        
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `ajustes_stock_detalle`
--

DROP TABLE IF EXISTS `ajustes_stock_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ajustes_stock_detalle` (
  `id_detalle` int NOT NULL AUTO_INCREMENT,
  `id_ajuste` int NOT NULL,
  `id_producto` int NOT NULL,
  `cod_barra` varchar(50) NOT NULL,
  `cantidad_sistema` int NOT NULL,
  `cantidad_ajuste` int NOT NULL DEFAULT '0',
  `observaciones` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_detalle`),
  KEY `idx_ajuste_detalle` (`id_ajuste`),
  KEY `idx_producto_ajuste` (`id_producto`,`cod_barra`),
  CONSTRAINT `fk_ajuste_cabecera` FOREIGN KEY (`id_ajuste`) REFERENCES `ajustes_stock_cabecera` (`id_ajuste`) ON DELETE CASCADE,
  CONSTRAINT `fk_ajuste_producto` FOREIGN KEY (`id_producto`, `cod_barra`) REFERENCES `productos_detalle` (`id_producto`, `cod_barra`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ajustes_stock_detalle`
--

LOCK TABLES `ajustes_stock_detalle` WRITE;
/*!40000 ALTER TABLE `ajustes_stock_detalle` DISABLE KEYS */;
INSERT INTO `ajustes_stock_detalle` VALUES (6,1,1,'7840058009456',0,30,'Carga Inicial');
/*!40000 ALTER TABLE `ajustes_stock_detalle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `caja_arqueo`
--

DROP TABLE IF EXISTS `caja_arqueo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `caja_arqueo` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_caja` int NOT NULL,
  `denominacion` int NOT NULL,
  `cantidad` int NOT NULL,
  `es_billete` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `id_caja` (`id_caja`),
  CONSTRAINT `caja_arqueo_ibfk_1` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_cantidad` CHECK ((`cantidad` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `caja_arqueo`
--

LOCK TABLES `caja_arqueo` WRITE;
/*!40000 ALTER TABLE `caja_arqueo` DISABLE KEYS */;
/*!40000 ALTER TABLE `caja_arqueo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cajas`
--

DROP TABLE IF EXISTS `cajas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cajas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `fecha_apertura` timestamp NOT NULL,
  `monto_apertura` bigint NOT NULL,
  `usuario_apertura` varchar(50) NOT NULL,
  `fecha_cierre` timestamp NULL DEFAULT NULL,
  `monto_cierre` bigint DEFAULT NULL,
  `monto_ventas` bigint DEFAULT NULL,
  `monto_gastos` bigint DEFAULT NULL,
  `diferencia` bigint DEFAULT NULL,
  `usuario_cierre` varchar(50) DEFAULT NULL,
  `estado_abierto` tinyint(1) NOT NULL DEFAULT '1',
  `observaciones` text,
  PRIMARY KEY (`id`),
  KEY `idx_cajas_estado` (`estado_abierto`),
  KEY `idx_cajas_fechas` (`fecha_apertura`,`fecha_cierre`),
  CONSTRAINT `chk_montos` CHECK (((`monto_apertura` >= 0) and ((`monto_cierre` is null) or (`monto_cierre` >= 0)) and ((`monto_ventas` is null) or (`monto_ventas` >= 0)) and ((`monto_gastos` is null) or (`monto_gastos` >= 0))))
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cajas`
--

LOCK TABLES `cajas` WRITE;
/*!40000 ALTER TABLE `cajas` DISABLE KEYS */;
INSERT INTO `cajas` VALUES (1,'2025-05-14 17:05:28',500000,'admin','2025-05-14 17:30:42',550000,50000,0,0,'Juanjo',0,NULL),(2,'2025-06-23 02:57:05',500000,'admin','2025-06-23 02:58:33',500000,0,0,0,'Juanjo',0,NULL);
/*!40000 ALTER TABLE `cajas` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Table structure for table `clientes`
--

DROP TABLE IF EXISTS `clientes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clientes` (
  `id_cliente` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) NOT NULL,
  `ci_ruc` varchar(20) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `direccion` text,
  `email` varchar(100) DEFAULT NULL,
  `estado` tinyint(1) DEFAULT '1',
  `id_persona` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_cliente`),
  UNIQUE KEY `uk_cliente_persona` (`id_persona`),
  KEY `idx_clientes_ci_ruc` (`ci_ruc`),
  KEY `idx_clientes_nombre` (`nombre`),
  KEY `idx_clientes_estado` (`estado`),
  KEY `idx_clientes_persona` (`id_persona`),
  CONSTRAINT `clientes_ibfk_1` FOREIGN KEY (`id_persona`) REFERENCES `personas` (`id_persona`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clientes`
--

LOCK TABLES `clientes` WRITE;
/*!40000 ALTER TABLE `clientes` DISABLE KEYS */;
INSERT INTO `clientes` VALUES (1,'Juan Manuel Lopez Roa','1124706','0971456189','','',1,1,'2025-05-29 00:56:46','2025-05-29 00:56:46'),(2,'CLIENTE OCASIONAL','80000000','','','',1,7,'2025-06-08 18:37:19','2025-06-08 18:37:19');
/*!40000 ALTER TABLE `clientes` ENABLE KEYS */;
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
-- Table structure for table `configuracion_ventas`
--

DROP TABLE IF EXISTS `configuracion_ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `configuracion_ventas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre_parametro` varchar(50) NOT NULL,
  `valor_parametro` varchar(255) NOT NULL,
  `descripcion` text,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre_parametro` (`nombre_parametro`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuracion_ventas`
--

LOCK TABLES `configuracion_ventas` WRITE;
/*!40000 ALTER TABLE `configuracion_ventas` DISABLE KEYS */;
INSERT INTO `configuracion_ventas` VALUES (1,'SERIE_FACTURA','001','Serie de la factura','2025-06-07 16:24:09'),(2,'NUMERO_FACTURA','0000002','Último número de factura utilizado','2025-06-07 16:33:48'),(3,'PREFIJO_FACTURA','FAC-','Prefijo para el número de factura','2025-06-07 16:24:09'),(4,'IVA_PORCENTAJE','10.00','Porcentaje de IVA por defecto','2025-06-07 16:24:09'),(5,'PERMITE_DESCUENTOS','true','Permite aplicar descuentos en las ventas','2025-06-07 16:24:09'),(6,'MAXIMO_DESCUENTO','50.00','Máximo porcentaje de descuento permitido','2025-06-07 16:24:09');
/*!40000 ALTER TABLE `configuracion_ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `devoluciones`
--

DROP TABLE IF EXISTS `devoluciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `devoluciones` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_venta_original` int NOT NULL,
  `id_venta_devolucion` int DEFAULT NULL,
  `fecha_devolucion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `motivo` text NOT NULL,
  `monto_devuelto` int NOT NULL,
  `usuario_autoriza` int DEFAULT NULL,
  `estado` enum('PENDIENTE','APROBADA','RECHAZADA') DEFAULT 'PENDIENTE',
  `observaciones` text,
  PRIMARY KEY (`id`),
  KEY `id_venta_devolucion` (`id_venta_devolucion`),
  KEY `idx_devoluciones_venta_original` (`id_venta_original`),
  KEY `idx_devoluciones_fecha` (`fecha_devolucion`),
  CONSTRAINT `devoluciones_ibfk_1` FOREIGN KEY (`id_venta_original`) REFERENCES `ventas` (`id`),
  CONSTRAINT `devoluciones_ibfk_2` FOREIGN KEY (`id_venta_devolucion`) REFERENCES `ventas` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `devoluciones`
--

LOCK TABLES `devoluciones` WRITE;
/*!40000 ALTER TABLE `devoluciones` DISABLE KEYS */;
/*!40000 ALTER TABLE `devoluciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `devoluciones_detalle`
--

DROP TABLE IF EXISTS `devoluciones_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `devoluciones_detalle` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_devolucion` int NOT NULL,
  `id_producto` int NOT NULL,
  `codigo_barra` varchar(50) NOT NULL,
  `cantidad_devuelta` int NOT NULL,
  `precio_unitario` int NOT NULL,
  `subtotal` int NOT NULL,
  `motivo_detalle` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_devoluciones_detalle_devolucion` (`id_devolucion`),
  CONSTRAINT `devoluciones_detalle_ibfk_1` FOREIGN KEY (`id_devolucion`) REFERENCES `devoluciones` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `devoluciones_detalle`
--

LOCK TABLES `devoluciones_detalle` WRITE;
/*!40000 ALTER TABLE `devoluciones_detalle` DISABLE KEYS */;
/*!40000 ALTER TABLE `devoluciones_detalle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gastos`
--

DROP TABLE IF EXISTS `gastos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `gastos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `fecha` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `monto` bigint NOT NULL,
  `concepto` varchar(255) NOT NULL,
  `id_caja` int DEFAULT NULL,
  `usuario` varchar(50) NOT NULL,
  `anulado` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `id_caja` (`id_caja`),
  CONSTRAINT `gastos_ibfk_1` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_monto_gasto` CHECK ((`monto` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gastos`
--

LOCK TABLES `gastos` WRITE;
/*!40000 ALTER TABLE `gastos` DISABLE KEYS */;
/*!40000 ALTER TABLE `gastos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ingresos_caja`
--

DROP TABLE IF EXISTS `ingresos_caja`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ingresos_caja` (
  `id` int NOT NULL AUTO_INCREMENT,
  `fecha` datetime NOT NULL,
  `monto` decimal(10,2) NOT NULL,
  `concepto` varchar(255) NOT NULL,
  `usuario` varchar(50) NOT NULL,
  `anulado` tinyint(1) NOT NULL DEFAULT '0',
  `id_caja` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id_caja` (`id_caja`),
  CONSTRAINT `ingresos_caja_ibfk_1` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ingresos_caja`
--

LOCK TABLES `ingresos_caja` WRITE;
/*!40000 ALTER TABLE `ingresos_caja` DISABLE KEYS */;
/*!40000 ALTER TABLE `ingresos_caja` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Table structure for table `menus`
--

DROP TABLE IF EXISTS `menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menus` (
  `id_menu` int NOT NULL AUTO_INCREMENT,
  `nombre_menu` varchar(100) NOT NULL,
  `nombre_componente` varchar(100) NOT NULL,
  `menu_padre` int DEFAULT NULL,
  `orden` int DEFAULT '0',
  `activo` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id_menu`),
  KEY `menu_padre` (`menu_padre`),
  CONSTRAINT `menus_ibfk_1` FOREIGN KEY (`menu_padre`) REFERENCES `menus` (`id_menu`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menus`
--

LOCK TABLES `menus` WRITE;
/*!40000 ALTER TABLE `menus` DISABLE KEYS */;
INSERT INTO `menus` VALUES (1,'Archivo','mArchivo',NULL,1,1),(2,'Nuevo','mNuevo',1,1,1),(3,'Guardar','mGuardar',1,2,1),(4,'Borrar','mBorrar',1,3,1),(5,'Buscar','mBuscar',1,4,1),(6,'Imprimir','mImprimir',1,5,1),(7,'Cerrar Ventana','mCerrarVentana',1,6,1),(8,'Salir','mSalir',1,7,1),(9,'Edición','mEdicion',NULL,2,1),(10,'Primero','mPrimero',9,1,1),(11,'Anterior','mAnterior',9,2,1),(12,'Siguiente','mSiguiente',9,3,1),(13,'Último','mUltimo',9,4,1),(14,'Ins. Detalle','mInsDetalle',9,5,1),(15,'Del. Detalle','mDelDetalle',9,6,1),(16,'Compras','mCompras',NULL,3,1),(17,'Proveedores','mProveedores',16,1,1),(18,'Registrar Compra','mRegCompras',16,2,1),(19,'Reporte Compras','mRepCompras',16,3,1),(20,'Ventas','mVentas',NULL,4,1),(21,'Clientes','mClientes',20,1,1),(22,'Talonarios','mTalonarios',20,2,1),(23,'Registrar Venta Directa','mRegVentaDirecta',20,3,1),(24,'Registrar Ventas','mRegVentas',20,4,1),(25,'Reporte Ventas','mRepVentas',20,5,1),(26,'Stock','mStock',NULL,5,1),(27,'Productos','mProductos',26,1,1),(28,'Lista Precios','mListaPrecios',26,2,1),(29,'Ajustar Stock','mAjustarStock',26,3,1),(30,'Aprobar Stock','mAprobarStock',26,4,1),(31,'Reporte Inventario','mRepInvent',26,5,1),(32,'Tesorería','mTesoreria',NULL,6,1),(33,'Apertura/Cierre Caja','mAperturaCierreCaja',32,1,1),(34,'Ingresar Caja','mIngCaja',32,2,1),(35,'Reporte Caja','mRepCaja',32,3,1),(36,'Seguridad','mSeguridad',NULL,7,1),(37,'Personas','mPersonas',36,1,1),(38,'Usuarios','mUsuarios',36,2,1),(39,'Roles','mRoles',36,3,1),(40,'Permisos','mPermisos',36,4,1),(41,'Menús','mMenus',36,5,1);
/*!40000 ALTER TABLE `menus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mesas`
--

DROP TABLE IF EXISTS `mesas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mesas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `numero` varchar(10) NOT NULL,
  `estado` varchar(50) DEFAULT 'Disponible',
  `posicion_x` int NOT NULL,
  `posicion_y` int NOT NULL,
  `capacidad` int DEFAULT '4',
  `ancho` int DEFAULT '60',
  `alto` int DEFAULT '60',
  `forma` varchar(20) DEFAULT 'CIRCULAR',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mesas`
--

LOCK TABLES `mesas` WRITE;
/*!40000 ALTER TABLE `mesas` DISABLE KEYS */;
INSERT INTO `mesas` VALUES (1,'1','Disponible',10,10,4,100,100,'CIRCULAR'),(2,'2','Disponible',120,10,4,100,100,'CIRCULAR'),(3,'3','Disponible',230,10,4,100,100,'CIRCULAR'),(4,'4','Disponible',340,10,4,100,100,'CIRCULAR'),(5,'5','Disponible',450,10,4,100,100,'CIRCULAR'),(6,'6','Disponible',10,120,4,100,100,'CIRCULAR'),(7,'7','Disponible',120,120,4,100,100,'CIRCULAR'),(8,'8','Disponible',230,120,4,100,100,'CIRCULAR'),(9,'9','Disponible',340,120,4,100,100,'CIRCULAR'),(10,'10','Disponible',450,120,4,100,100,'CIRCULAR'),(23,'11','Disponible',10,230,4,100,100,'RECTANGULAR'),(24,'12','Disponible',120,230,4,100,100,'RECTANGULAR'),(25,'13','Disponible',230,230,4,100,100,'RECTANGULAR'),(27,'15','Disponible',450,230,4,100,100,'RECTANGULAR'),(38,'16','Disponible',450,230,4,100,100,'RECTANGULAR');
/*!40000 ALTER TABLE `mesas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `permisos`
--

DROP TABLE IF EXISTS `permisos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `permisos` (
  `id_permiso` int NOT NULL AUTO_INCREMENT,
  `id_rol` int NOT NULL,
  `id_menu` int NOT NULL,
  `ver` tinyint(1) DEFAULT '0',
  `crear` tinyint(1) DEFAULT '0',
  `leer` tinyint(1) DEFAULT '0',
  `actualizar` tinyint(1) DEFAULT '0',
  `eliminar` tinyint(1) DEFAULT '0',
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_permiso`),
  UNIQUE KEY `uk_rol_menu` (`id_rol`,`id_menu`),
  KEY `id_menu` (`id_menu`),
  CONSTRAINT `permisos_ibfk_1` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`) ON DELETE CASCADE,
  CONSTRAINT `permisos_ibfk_2` FOREIGN KEY (`id_menu`) REFERENCES `menus` (`id_menu`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=262 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `permisos`
--

LOCK TABLES `permisos` WRITE;
/*!40000 ALTER TABLE `permisos` DISABLE KEYS */;
INSERT INTO `permisos` VALUES (1,1,1,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(2,1,2,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(3,1,3,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(4,1,4,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(5,1,5,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(6,1,6,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(7,1,7,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(8,1,8,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(9,1,9,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(10,1,10,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(11,1,11,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(12,1,12,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(13,1,13,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(14,1,14,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(15,1,15,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(16,1,16,1,1,1,1,1,'2025-06-25 16:15:33','2025-06-25 16:15:33'),(17,1,17,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(18,1,18,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(19,1,19,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(20,1,20,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(21,1,21,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(22,1,22,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(23,1,23,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(24,1,24,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(25,1,25,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(26,1,26,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(27,1,27,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(28,1,28,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(29,1,29,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(30,1,30,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(31,1,31,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(32,1,32,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(33,1,33,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(34,1,34,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(35,1,35,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(36,1,36,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(37,1,37,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(38,1,38,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(39,1,39,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(40,1,40,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(41,1,41,1,1,1,1,1,'2025-06-25 16:15:34','2025-06-25 16:15:34'),(124,2,1,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(125,2,2,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(126,2,3,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(127,2,4,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(128,2,5,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(129,2,6,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(130,2,7,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(131,2,8,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(132,2,9,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(133,2,10,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(134,2,11,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(135,2,12,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(136,2,13,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(137,2,14,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(138,2,15,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(139,2,20,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:51:03'),(140,2,21,1,1,1,0,0,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(141,2,22,1,1,1,0,0,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(142,2,23,1,1,1,1,0,'2025-06-27 01:19:19','2025-06-27 01:51:03'),(143,2,24,1,1,1,1,0,'2025-06-27 01:19:19','2025-06-27 01:51:03'),(144,2,26,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:51:03'),(145,2,27,1,1,1,1,0,'2025-06-27 01:19:19','2025-06-28 20:31:31'),(146,2,28,1,1,1,1,0,'2025-06-27 01:19:19','2025-06-28 20:31:31'),(147,2,32,1,1,1,1,1,'2025-06-27 01:19:19','2025-06-27 01:51:03'),(148,2,33,1,1,1,1,0,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(149,2,34,1,1,1,1,0,'2025-06-27 01:19:19','2025-06-27 01:51:03'),(150,2,35,1,1,1,1,0,'2025-06-27 01:19:19','2025-06-27 01:19:19'),(225,2,25,1,1,1,1,0,'2025-06-28 20:31:31','2025-06-28 20:31:31'),(257,2,31,1,1,1,1,0,'2025-06-28 20:52:36','2025-06-28 20:52:36');
/*!40000 ALTER TABLE `permisos` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personas`
--

LOCK TABLES `personas` WRITE;
/*!40000 ALTER TABLE `personas` DISABLE KEYS */;
INSERT INTO `personas` VALUES (1,'Juan Manuel','Lopez Roa','1124706','0971456189','','1971-06-24',1),(2,'Evelina Patricia','Bernal Gamarra','1823306','0971440753','evelina-bernal11@hotmail.com','1973-07-11',1),(3,'Juan Jose','Lopez Bernal','3818632','0972541782','','1994-09-24',1),(4,'PARAGUAY REFRESCOS S.A.','','80003400-7','021-9591661','info@koandina.com','2022-08-17',1),(5,'EMCESA S.A.C.I.','','80006251-5','021-585002','','2023-03-17',1),(6,'CERVEPAR S.A.','','80086846-3','021-5886003','atencionalcliente@cervepar.com.py','2021-01-08',0),(7,'CLIENTE OCASIONAL','','80000000','','','2025-01-01',1);
/*!40000 ALTER TABLE `personas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `precio_cabecera`
--

DROP TABLE IF EXISTS `precio_cabecera`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `precio_cabecera` (
  `id` int NOT NULL AUTO_INCREMENT,
  `fecha_creacion` date NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `moneda` varchar(10) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `observaciones` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `precio_cabecera`
--

LOCK TABLES `precio_cabecera` WRITE;
/*!40000 ALTER TABLE `precio_cabecera` DISABLE KEYS */;
INSERT INTO `precio_cabecera` VALUES (1,'2025-06-06','Precio de Menú','PYG',1,'Precio que tienen los productos para clientes que\npiden productos en el local según carta/menú');
/*!40000 ALTER TABLE `precio_cabecera` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `precio_detalle`
--

DROP TABLE IF EXISTS `precio_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `precio_detalle` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_precio_cabecera` int NOT NULL,
  `codigo_barra` varchar(50) NOT NULL,
  `precio` decimal(15,2) NOT NULL,
  `fecha_vigencia` date NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_precio_producto` (`id_precio_cabecera`,`codigo_barra`),
  KEY `codigo_barra` (`codigo_barra`),
  CONSTRAINT `precio_detalle_ibfk_1` FOREIGN KEY (`id_precio_cabecera`) REFERENCES `precio_cabecera` (`id`),
  CONSTRAINT `precio_detalle_ibfk_2` FOREIGN KEY (`codigo_barra`) REFERENCES `productos_detalle` (`cod_barra`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `precio_detalle`
--

LOCK TABLES `precio_detalle` WRITE;
/*!40000 ALTER TABLE `precio_detalle` DISABLE KEYS */;
INSERT INTO `precio_detalle` VALUES (1,1,'7790040320015',7000.00,'2025-06-07',1),(2,1,'7840058009456',15000.00,'2025-06-07',1),(3,1,'7790040320039',7000.00,'2025-06-07',1),(5,1,'70847037033',10000.00,'2025-06-07',1),(6,1,'7840025110864',12000.00,'2025-06-23',1);
/*!40000 ALTER TABLE `precio_detalle` ENABLE KEYS */;
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
INSERT INTO `roles` VALUES (1,'Administrador',1),(2,'Cajero',1);
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
  `cantidad_disponible` int DEFAULT '0',
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
INSERT INTO `stock` VALUES (1,'7840058009456',0,'2025-06-22 22:09:00',0.00);
/*!40000 ALTER TABLE `stock` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `talonarios`
--

DROP TABLE IF EXISTS `talonarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `talonarios` (
  `id_talonario` int NOT NULL AUTO_INCREMENT,
  `numero_timbrado` varchar(50) NOT NULL,
  `fecha_vencimiento` datetime NOT NULL,
  `factura_desde` int NOT NULL,
  `factura_hasta` int NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `tipo_comprobante` varchar(50) NOT NULL,
  `punto_expedicion` varchar(3) NOT NULL,
  `establecimiento` varchar(3) NOT NULL,
  `factura_actual` int NOT NULL,
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_talonario`),
  KEY `idx_talonario_estado` (`estado`),
  KEY `idx_talonario_timbrado` (`numero_timbrado`),
  CONSTRAINT `chk_factura_actual` CHECK (((`factura_actual` >= `factura_desde`) and (`factura_actual` <= `factura_hasta`))),
  CONSTRAINT `chk_factura_rango` CHECK ((`factura_hasta` > `factura_desde`))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `talonarios`
--

LOCK TABLES `talonarios` WRITE;
/*!40000 ALTER TABLE `talonarios` DISABLE KEYS */;
INSERT INTO `talonarios` VALUES (1,'17766617','2026-01-31 00:00:00',351,550,1,'FACTURA','001','001',401,'2025-06-21 15:22:11','2025-06-21 15:23:55');
/*!40000 ALTER TABLE `talonarios` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,2,2,'eve','$2a$10$9irsYJejgEPDrlxzWQkGPO.rgUM1NPAUtSvxqaUGJHcxi92wZ1NMO',1),(2,1,1,'lopo','$2a$10$J7eIQhno5NS1C.okVa8y1ugrraLaGNIWpOr2N2T5vlHjVh/.6sgBC',1);
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_cajas_activas`
--

DROP TABLE IF EXISTS `v_cajas_activas`;
/*!50001 DROP VIEW IF EXISTS `v_cajas_activas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_cajas_activas` AS SELECT 
 1 AS `id`,
 1 AS `fecha_apertura`,
 1 AS `monto_apertura`,
 1 AS `usuario_apertura`,
 1 AS `horas_abierta`,
 1 AS `estado_abierto`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_productos_mas_vendidos`
--

DROP TABLE IF EXISTS `v_productos_mas_vendidos`;
/*!50001 DROP VIEW IF EXISTS `v_productos_mas_vendidos`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_productos_mas_vendidos` AS SELECT 
 1 AS `id_producto`,
 1 AS `codigo_barra`,
 1 AS `descripcion_producto`,
 1 AS `cantidad_total_vendida`,
 1 AS `monto_total_vendido`,
 1 AS `numero_ventas`,
 1 AS `precio_promedio`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_rendimiento_cajas`
--

DROP TABLE IF EXISTS `v_rendimiento_cajas`;
/*!50001 DROP VIEW IF EXISTS `v_rendimiento_cajas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_rendimiento_cajas` AS SELECT 
 1 AS `fecha`,
 1 AS `cantidad_cajas`,
 1 AS `total_apertura`,
 1 AS `total_ventas`,
 1 AS `total_gastos`,
 1 AS `rendimiento_neto`,
 1 AS `total_diferencias`,
 1 AS `total_sobrantes`,
 1 AS `total_faltantes`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_ventas_completas`
--

DROP TABLE IF EXISTS `v_ventas_completas`;
/*!50001 DROP VIEW IF EXISTS `v_ventas_completas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_ventas_completas` AS SELECT 
 1 AS `id`,
 1 AS `fecha`,
 1 AS `numero_factura`,
 1 AS `total`,
 1 AS `subtotal`,
 1 AS `impuesto_total`,
 1 AS `descuento_monto`,
 1 AS `metodo_pago`,
 1 AS `tipo_venta`,
 1 AS `estado`,
 1 AS `anulado`,
 1 AS `cliente_nombre`,
 1 AS `cliente_documento`,
 1 AS `cliente_telefono`,
 1 AS `cliente_direccion`,
 1 AS `usuario_nombre`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_ventas_simples`
--

DROP TABLE IF EXISTS `v_ventas_simples`;
/*!50001 DROP VIEW IF EXISTS `v_ventas_simples`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_ventas_simples` AS SELECT 
 1 AS `id`,
 1 AS `fecha`,
 1 AS `numero_factura`,
 1 AS `total`,
 1 AS `anulado`,
 1 AS `cliente_nombre`,
 1 AS `cliente_documento`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `ventas`
--

DROP TABLE IF EXISTS `ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ventas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `fecha` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `total` bigint NOT NULL,
  `id_cliente` int DEFAULT NULL,
  `id_usuario` int NOT NULL,
  `id_caja` int DEFAULT NULL,
  `anulado` tinyint(1) NOT NULL DEFAULT '0',
  `observaciones` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `metodo_pago` enum('EFECTIVO','TARJETA','TRANSFERENCIA','CHEQUE','MIXTO') DEFAULT 'EFECTIVO',
  `descuento_porcentaje` decimal(5,2) DEFAULT '0.00',
  `descuento_monto` int DEFAULT '0',
  `subtotal` int DEFAULT '0',
  `impuesto_total` int DEFAULT '0',
  `numero_factura` varchar(50) DEFAULT NULL,
  `numero_timbrado` varchar(50) DEFAULT NULL,
  `tipo_venta` enum('CONTADO','CREDITO') DEFAULT 'CONTADO',
  `estado` enum('PENDIENTE','PAGADA','ANULADA','CREDITO') DEFAULT 'PENDIENTE',
  PRIMARY KEY (`id`),
  UNIQUE KEY `numero_factura` (`numero_factura`),
  KEY `idx_ventas_fecha` (`fecha`),
  KEY `idx_ventas_caja` (`id_caja`),
  KEY `idx_ventas_anulado` (`anulado`),
  KEY `idx_ventas_cliente` (`id_cliente`),
  KEY `idx_ventas_usuario` (`id_usuario`),
  KEY `idx_ventas_estado` (`estado`),
  KEY `idx_ventas_tipo` (`tipo_venta`),
  KEY `idx_ventas_numero_factura` (`numero_factura`),
  KEY `idx_ventas_timbrado` (`numero_timbrado`),
  CONSTRAINT `ventas_ibfk_1` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_total_venta` CHECK ((`total` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas`
--

LOCK TABLES `ventas` WRITE;
/*!40000 ALTER TABLE `ventas` DISABLE KEYS */;
/*!40000 ALTER TABLE `ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ventas_detalle`
--

DROP TABLE IF EXISTS `ventas_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ventas_detalle` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_venta` int NOT NULL,
  `id_producto` int NOT NULL,
  `codigo_barra` varchar(50) NOT NULL,
  `cantidad` int NOT NULL,
  `precio_unitario` bigint NOT NULL,
  `subtotal` bigint NOT NULL,
  `descripcion_producto` varchar(255) DEFAULT NULL,
  `costo_unitario` int DEFAULT '0',
  `descuento_porcentaje` decimal(5,2) DEFAULT '0.00',
  `descuento_monto` int DEFAULT '0',
  `precio_original` int DEFAULT '0',
  `base_imponible` int DEFAULT '0',
  `impuesto_monto` int DEFAULT '0',
  `impuesto_porcentaje` decimal(5,2) DEFAULT '10.00',
  `lote` varchar(50) DEFAULT NULL,
  `fecha_vencimiento` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ventas_detalle_venta` (`id_venta`),
  KEY `idx_ventas_detalle_producto` (`id_producto`),
  KEY `idx_ventas_detalle_codigo` (`codigo_barra`),
  CONSTRAINT `ventas_detalle_ibfk_1` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_cantidad_venta` CHECK ((`cantidad` > 0)),
  CONSTRAINT `chk_precio_venta` CHECK ((`precio_unitario` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas_detalle`
--

LOCK TABLES `ventas_detalle` WRITE;
/*!40000 ALTER TABLE `ventas_detalle` DISABLE KEYS */;
/*!40000 ALTER TABLE `ventas_detalle` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_actualizar_totales_insert` AFTER INSERT ON `ventas_detalle` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_actualizar_totales_update` AFTER UPDATE ON `ventas_detalle` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_actualizar_totales_delete` AFTER DELETE ON `ventas_detalle` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `ventas_historico`
--

DROP TABLE IF EXISTS `ventas_historico`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ventas_historico` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_venta` int NOT NULL,
  `accion` enum('CREADA','MODIFICADA','ANULADA','RESTAURADA') NOT NULL,
  `usuario_id` int DEFAULT NULL,
  `fecha_accion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `datos_anteriores` text,
  `datos_nuevos` text,
  `motivo` text,
  `ip_address` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ventas_historico_venta` (`id_venta`),
  KEY `idx_ventas_historico_fecha` (`fecha_accion`),
  CONSTRAINT `ventas_historico_ibfk_1` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas_historico`
--

LOCK TABLES `ventas_historico` WRITE;
/*!40000 ALTER TABLE `ventas_historico` DISABLE KEYS */;
/*!40000 ALTER TABLE `ventas_historico` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ventas_pagos`
--

DROP TABLE IF EXISTS `ventas_pagos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ventas_pagos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_venta` int NOT NULL,
  `metodo_pago` enum('EFECTIVO','TARJETA','TRANSFERENCIA','CHEQUE') NOT NULL,
  `monto` int NOT NULL,
  `referencia` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ventas_pagos_venta` (`id_venta`),
  KEY `idx_ventas_pagos_metodo` (`metodo_pago`),
  CONSTRAINT `ventas_pagos_ibfk_1` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas_pagos`
--

LOCK TABLES `ventas_pagos` WRITE;
/*!40000 ALTER TABLE `ventas_pagos` DISABLE KEYS */;
/*!40000 ALTER TABLE `ventas_pagos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'proyecto2'
--

--
-- Dumping routines for database 'proyecto2'
--
/*!50003 DROP FUNCTION IF EXISTS `fn_generar_numero_factura` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_generar_numero_factura`() RETURNS varchar(50) CHARSET utf8mb4
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `hay_caja_abierta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `hay_caja_abierta`() RETURNS tinyint(1)
    READS SQL DATA
BEGIN
    DECLARE cuenta INT;
    SELECT COUNT(*) INTO cuenta FROM cajas WHERE estado_abierto = TRUE;
    RETURN cuenta > 0;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `abrir_caja` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `abrir_caja`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
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
/*!50003 DROP PROCEDURE IF EXISTS `cerrar_caja` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `cerrar_caja`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `limpiar_arqueos_caja` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `limpiar_arqueos_caja`(
    IN p_id_caja INT
)
    MODIFIES SQL DATA
BEGIN
    DELETE FROM caja_arqueo WHERE id_caja = p_id_caja;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `obtener_resumen_caja` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `obtener_resumen_caja`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `registrar_arqueo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `registrar_arqueo`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_anular_venta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_anular_venta`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `v_cajas_activas`
--

/*!50001 DROP VIEW IF EXISTS `v_cajas_activas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_cajas_activas` AS select `cajas`.`id` AS `id`,`cajas`.`fecha_apertura` AS `fecha_apertura`,`cajas`.`monto_apertura` AS `monto_apertura`,`cajas`.`usuario_apertura` AS `usuario_apertura`,timestampdiff(HOUR,`cajas`.`fecha_apertura`,now()) AS `horas_abierta`,`cajas`.`estado_abierto` AS `estado_abierto` from `cajas` where (`cajas`.`estado_abierto` = true) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_productos_mas_vendidos`
--

/*!50001 DROP VIEW IF EXISTS `v_productos_mas_vendidos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_productos_mas_vendidos` AS select `vd`.`id_producto` AS `id_producto`,`vd`.`codigo_barra` AS `codigo_barra`,coalesce(`vd`.`descripcion_producto`,'Sin descripción') AS `descripcion_producto`,sum(`vd`.`cantidad`) AS `cantidad_total_vendida`,sum(`vd`.`subtotal`) AS `monto_total_vendido`,count(distinct `vd`.`id_venta`) AS `numero_ventas`,avg(`vd`.`precio_unitario`) AS `precio_promedio` from (`ventas_detalle` `vd` join `ventas` `v` on((`vd`.`id_venta` = `v`.`id`))) where (`v`.`anulado` = false) group by `vd`.`id_producto`,`vd`.`codigo_barra`,`vd`.`descripcion_producto` order by `cantidad_total_vendida` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_rendimiento_cajas`
--

/*!50001 DROP VIEW IF EXISTS `v_rendimiento_cajas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_rendimiento_cajas` AS select cast(`cajas`.`fecha_apertura` as date) AS `fecha`,count(0) AS `cantidad_cajas`,sum(`cajas`.`monto_apertura`) AS `total_apertura`,sum(`cajas`.`monto_ventas`) AS `total_ventas`,sum(`cajas`.`monto_gastos`) AS `total_gastos`,sum((`cajas`.`monto_ventas` - `cajas`.`monto_gastos`)) AS `rendimiento_neto`,sum(abs(`cajas`.`diferencia`)) AS `total_diferencias`,sum(if((`cajas`.`diferencia` > 0),`cajas`.`diferencia`,0)) AS `total_sobrantes`,sum(if((`cajas`.`diferencia` < 0),abs(`cajas`.`diferencia`),0)) AS `total_faltantes` from `cajas` where (`cajas`.`estado_abierto` = false) group by cast(`cajas`.`fecha_apertura` as date) order by `fecha` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_ventas_completas`
--

/*!50001 DROP VIEW IF EXISTS `v_ventas_completas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_ventas_completas` AS select `v`.`id` AS `id`,`v`.`fecha` AS `fecha`,`v`.`numero_factura` AS `numero_factura`,`v`.`total` AS `total`,coalesce(`v`.`subtotal`,`v`.`total`) AS `subtotal`,coalesce(`v`.`impuesto_total`,0) AS `impuesto_total`,coalesce(`v`.`descuento_monto`,0) AS `descuento_monto`,coalesce(`v`.`metodo_pago`,'EFECTIVO') AS `metodo_pago`,coalesce(`v`.`tipo_venta`,'CONTADO') AS `tipo_venta`,coalesce(`v`.`estado`,'PAGADA') AS `estado`,`v`.`anulado` AS `anulado`,`c`.`nombre` AS `cliente_nombre`,`c`.`ci_ruc` AS `cliente_documento`,`c`.`telefono` AS `cliente_telefono`,`c`.`direccion` AS `cliente_direccion`,`u`.`NombreUsuario` AS `usuario_nombre` from ((`ventas` `v` left join `clientes` `c` on((`v`.`id_cliente` = `c`.`id_cliente`))) left join `usuarios` `u` on((`v`.`id_usuario` = `u`.`UsuarioID`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_ventas_simples`
--

/*!50001 DROP VIEW IF EXISTS `v_ventas_simples`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_ventas_simples` AS select `v`.`id` AS `id`,`v`.`fecha` AS `fecha`,`v`.`numero_factura` AS `numero_factura`,`v`.`total` AS `total`,`v`.`anulado` AS `anulado`,`c`.`nombre` AS `cliente_nombre`,`c`.`ci_ruc` AS `cliente_documento` from (`ventas` `v` left join `clientes` `c` on((`v`.`id_cliente` = `c`.`id_cliente`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-06-28 18:01:31
