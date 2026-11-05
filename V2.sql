-- Marketplace UPIIT V2

DROP DATABASE IF EXISTS marketplaceupiit;
CREATE DATABASE marketplaceupiit
 CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE marketplaceupiit;

-- ---------------------------------------------------------
-- 1. TABLAS PRINCIPALES


CREATE TABLE usuario (
 id_usuario INT AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(100) NOT NULL,
 correo VARCHAR(150) NOT NULL UNIQUE,
 contrasena_hash VARCHAR(255) NOT NULL,
 tipo_usuario ENUM('COMPRADOR','VENDEDOR','AMBOS','ADMIN') NOT NULL DEFAULT 'COMPRADOR',
 estado ENUM('ACTIVO','SUSPENDIDO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
 fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- La tabla vendedor identifica a los usuarios que pueden publicar.
CREATE TABLE vendedor (
 id_usuario INT PRIMARY KEY,
 FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
  ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE horario (
 id_horario INT AUTO_INCREMENT PRIMARY KEY,
 id_vendedor INT NOT NULL,
 dia ENUM('LUNES','MARTES','MIERCOLES','JUEVES','VIERNES','SABADO','DOMINGO') NOT NULL,
 hora_inicio TIME NOT NULL,
 hora_fin TIME NOT NULL,
 CONSTRAINT chk_horario CHECK (hora_fin > hora_inicio),
 FOREIGN KEY (id_vendedor) REFERENCES vendedor(id_usuario)
  ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Cada producto pertenece al usuario que lo registro.
CREATE TABLE producto (
 id_producto INT AUTO_INCREMENT PRIMARY KEY,
 id_usuario INT NOT NULL,
 nombre VARCHAR(100) NOT NULL,
 descripcion TEXT,
 estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
 fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
  ON DELETE RESTRICT ON UPDATE CASCADE,
 INDEX idx_producto_usuario(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE producto_ingrediente (
 id_producto INT NOT NULL,
 ingrediente VARCHAR(100) NOT NULL,
 PRIMARY KEY(id_producto, ingrediente),
 FOREIGN KEY(id_producto) REFERENCES producto(id_producto)
  ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE producto_alergeno (
 id_producto INT NOT NULL,
 alergeno VARCHAR(100) NOT NULL,
 PRIMARY KEY(id_producto, alergeno),
 FOREIGN KEY(id_producto) REFERENCES producto(id_producto)
  ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE imagen (
 id_imagen INT AUTO_INCREMENT PRIMARY KEY,
 id_producto INT NOT NULL,
 FOREIGN KEY(id_producto) REFERENCES producto(id_producto)
  ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE imagen_archivo (
 id_imagen INT NOT NULL,
 archivo VARCHAR(255) NOT NULL,
 PRIMARY KEY(id_imagen, archivo),
 FOREIGN KEY(id_imagen) REFERENCES imagen(id_imagen)
  ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ubicacion (
 id_ubicacion INT AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(100) NOT NULL,
 descripcion TEXT,
 estado ENUM('ACTIVA','INACTIVA') NOT NULL DEFAULT 'ACTIVA'
) ENGINE=InnoDB;

-- Una publicacion puede ofrecer varios productos y comparte horario
-- y ubicacion de entrega para todas las reservas que genere.
CREATE TABLE publicacion (
 id_publicacion INT AUTO_INCREMENT PRIMARY KEY,
 id_vendedor INT NOT NULL,
 fecha_publicacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 fecha_hora_inicio DATETIME NOT NULL,
 fecha_hora_fin DATETIME NOT NULL,
 estado ENUM('BORRADOR','ACTIVA','AGOTADA','FINALIZADA','CANCELADA')
  NOT NULL DEFAULT 'BORRADOR',
 CONSTRAINT chk_publicacion_periodo CHECK(fecha_hora_fin > fecha_hora_inicio),
 FOREIGN KEY(id_vendedor) REFERENCES vendedor(id_usuario)
  ON DELETE RESTRICT ON UPDATE CASCADE,
 INDEX idx_publicacion_estado_horario(estado,fecha_hora_inicio,fecha_hora_fin)
) ENGINE=InnoDB;

-- Precio y cantidades dependen de cada producto dentro de una publicacion.
CREATE TABLE detalle_publicacion (
 id_detalle_publicacion INT AUTO_INCREMENT PRIMARY KEY,
 id_publicacion INT NOT NULL,
 id_producto INT NOT NULL,
 precio DECIMAL(10,2) NOT NULL,
 cantidad_publicada INT NOT NULL,
 cantidad_disponible INT NOT NULL,
 estado ENUM('DISPONIBLE','AGOTADO','RETIRADO') NOT NULL DEFAULT 'DISPONIBLE',
 CONSTRAINT uq_publicacion_producto UNIQUE(id_publicacion,id_producto),
 CONSTRAINT uq_detalle_publicacion_par UNIQUE(id_detalle_publicacion,id_publicacion),
 CONSTRAINT chk_dp_precio CHECK(precio >= 0),
 CONSTRAINT chk_dp_cantidad CHECK(cantidad_publicada > 0),
 CONSTRAINT chk_dp_disponible CHECK(cantidad_disponible >= 0
  AND cantidad_disponible <= cantidad_publicada),
 FOREIGN KEY(id_publicacion) REFERENCES publicacion(id_publicacion)
  ON DELETE CASCADE ON UPDATE CASCADE,
 FOREIGN KEY(id_producto) REFERENCES producto(id_producto)
  ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Una reserva corresponde a una sola publicacion.
CREATE TABLE reserva (
 id_reserva INT AUTO_INCREMENT PRIMARY KEY,
 id_comprador INT NOT NULL,
 id_publicacion INT NOT NULL,
 id_ubicacion INT NOT NULL,
 fecha_reserva DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 estado ENUM('PENDIENTE','CONFIRMADA','COMPLETADA','CANCELADA')
  NOT NULL DEFAULT 'PENDIENTE',
 CONSTRAINT uq_reserva_publicacion UNIQUE(id_reserva,id_publicacion),
 FOREIGN KEY(id_comprador) REFERENCES usuario(id_usuario)
  ON DELETE RESTRICT ON UPDATE CASCADE,
 FOREIGN KEY(id_publicacion) REFERENCES publicacion(id_publicacion)
  ON DELETE RESTRICT ON UPDATE CASCADE,
 FOREIGN KEY(id_ubicacion) REFERENCES ubicacion(id_ubicacion)
  ON DELETE RESTRICT ON UPDATE CASCADE,
 INDEX idx_reserva_fecha_estado(fecha_reserva,estado)
) ENGINE=InnoDB;

-- La FK compuesta obliga a que todos los detalles de una reserva
-- pertenezcan a la misma publicacion que la reserva principal.
CREATE TABLE detalle_reserva (
 id_detalle_reserva INT AUTO_INCREMENT PRIMARY KEY,
 id_reserva INT NOT NULL,
 id_publicacion INT NOT NULL,
 id_detalle_publicacion INT NOT NULL,
 cantidad INT NOT NULL,
 precio_unitario DECIMAL(10,2) NOT NULL,
 CONSTRAINT uq_reserva_detalle UNIQUE(id_reserva,id_detalle_publicacion),
 CONSTRAINT chk_dr_cantidad CHECK(cantidad > 0),
 CONSTRAINT chk_dr_precio CHECK(precio_unitario >= 0),
 FOREIGN KEY(id_reserva,id_publicacion)
  REFERENCES reserva(id_reserva,id_publicacion)
  ON DELETE CASCADE ON UPDATE CASCADE,
 FOREIGN KEY(id_detalle_publicacion,id_publicacion)
  REFERENCES detalle_publicacion(id_detalle_publicacion,id_publicacion)
  ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Relaciona cada cuenta individual de MySQL con su usuario de la aplicacion.
-- Permite que los procedimientos identifiquen al propietario sin recibir
-- un id_usuario arbitrario desde el cliente.
CREATE TABLE cuenta_aplicacion (
 usuario_sql VARCHAR(80) PRIMARY KEY,
 id_usuario INT NOT NULL UNIQUE,
 FOREIGN KEY(id_usuario) REFERENCES usuario(id_usuario)
  ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 2. TRIGGERS DE VALIDACION

DELIMITER $$

CREATE TRIGGER trg_detalle_publicacion_propietario_bi
BEFORE INSERT ON detalle_publicacion
FOR EACH ROW
BEGIN
 DECLARE v_vendedor INT DEFAULT NULL;
 DECLARE v_propietario INT DEFAULT NULL;

 SELECT id_vendedor INTO v_vendedor
 FROM publicacion WHERE id_publicacion=NEW.id_publicacion;

 SELECT id_usuario INTO v_propietario
 FROM producto WHERE id_producto=NEW.id_producto;

 IF v_vendedor IS NULL OR v_propietario IS NULL
    OR v_vendedor <> v_propietario THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='El producto debe pertenecer al vendedor de la publicacion.';
 END IF;
END$$

CREATE TRIGGER trg_detalle_publicacion_propietario_bu
BEFORE UPDATE ON detalle_publicacion
FOR EACH ROW
BEGIN
 DECLARE v_vendedor INT DEFAULT NULL;
 DECLARE v_propietario INT DEFAULT NULL;

 SELECT id_vendedor INTO v_vendedor
 FROM publicacion WHERE id_publicacion=NEW.id_publicacion;

 SELECT id_usuario INTO v_propietario
 FROM producto WHERE id_producto=NEW.id_producto;

 IF v_vendedor IS NULL OR v_propietario IS NULL
    OR v_vendedor <> v_propietario THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='El producto debe pertenecer al vendedor de la publicacion.';
 END IF;
END$$
DELIMITER ;

-- ---------------------------------------------------------
-- 3. DOS VISTAS PARA ADMINISTRADORES


-- Vista 1: indicadores generales. Los estados se cuentan por separado.
CREATE OR REPLACE VIEW vista_admin_resumen AS
SELECT
 (SELECT COUNT(*) FROM usuario) AS usuarios_registrados,
 (SELECT COUNT(*) FROM usuario WHERE estado='ACTIVO') AS usuarios_activos,
 (SELECT COUNT(*) FROM vendedor) AS vendedores,
 (SELECT COUNT(*) FROM producto) AS productos_registrados,
 (SELECT COUNT(*) FROM publicacion) AS publicaciones_totales,
 (SELECT COUNT(*) FROM publicacion WHERE estado='ACTIVA'
    AND NOW() BETWEEN fecha_hora_inicio AND fecha_hora_fin) AS publicaciones_activas_ahora,
 (SELECT COUNT(*) FROM publicacion WHERE estado='BORRADOR') AS publicaciones_borrador,
 (SELECT COUNT(*) FROM publicacion WHERE estado='AGOTADA') AS publicaciones_agotadas,
 (SELECT COUNT(*) FROM publicacion WHERE estado='FINALIZADA') AS publicaciones_finalizadas,
 (SELECT COUNT(*) FROM reserva) AS reservas_totales,
 (SELECT COUNT(*) FROM reserva WHERE DATE(fecha_reserva)=CURRENT_DATE()) AS reservas_hoy,
 (SELECT COUNT(*) FROM reserva WHERE estado='PENDIENTE') AS reservas_pendientes,
 (SELECT COUNT(*) FROM ubicacion WHERE estado='ACTIVA') AS ubicaciones_activas;

-- Vista 2: detalle operativo para filtrar desde la aplicacion o con SQL.
-- Una fila por producto reservado. Incluye datos de publicacion, vendedor,
-- comprador, ubicacion, cantidades, precios y subtotal.
CREATE OR REPLACE VIEW vista_admin_detalle_operativo AS
SELECT
 p.id_publicacion,
 p.estado AS estado_publicacion,
 p.fecha_publicacion,
 p.fecha_hora_inicio,
 p.fecha_hora_fin,
 uv.id_usuario AS id_vendedor,
 uv.nombre AS vendedor,
 r.id_reserva,
 r.fecha_reserva,
 r.estado AS estado_reserva,
 uc.id_usuario AS id_comprador,
 uc.nombre AS comprador,
 ub.id_ubicacion,
 ub.nombre AS ubicacion_entrega,
 pr.id_producto,
 pr.nombre AS producto,
 dp.precio AS precio_publicado,
 dr.cantidad,
 dr.precio_unitario,
 (dr.cantidad * dr.precio_unitario) AS subtotal,
 dp.cantidad_publicada,
 dp.cantidad_disponible,
 dp.estado AS estado_producto_publicado
FROM publicacion p
JOIN usuario uv ON uv.id_usuario=p.id_vendedor
LEFT JOIN detalle_publicacion dp ON dp.id_publicacion=p.id_publicacion
LEFT JOIN producto pr ON pr.id_producto=dp.id_producto
LEFT JOIN reserva r ON r.id_publicacion=p.id_publicacion
LEFT JOIN usuario uc ON uc.id_usuario=r.id_comprador
LEFT JOIN ubicacion ub ON ub.id_ubicacion=r.id_ubicacion
LEFT JOIN detalle_reserva dr
 ON dr.id_reserva=r.id_reserva
 AND dr.id_detalle_publicacion=dp.id_detalle_publicacion;

-- Ejemplos de consultas administrativas sobre la segunda vista:
-- SELECT * FROM vista_admin_detalle_operativo;
-- SELECT * FROM vista_admin_detalle_operativo WHERE estado_reserva='PENDIENTE';
-- SELECT * FROM vista_admin_detalle_operativo WHERE id_vendedor=1;
-- SELECT * FROM vista_admin_detalle_operativo
--   WHERE fecha_reserva >= CURRENT_DATE()
--     AND fecha_reserva < CURRENT_DATE() + INTERVAL 1 DAY;
-- SELECT vendedor, COUNT(DISTINCT id_publicacion) AS publicaciones
--   FROM vista_admin_detalle_operativo GROUP BY id_vendedor,vendedor;

-- ---------------------------------------------------------
-- VISTAS PARA SIMULAR LA INTERFAZ DE LOS USUARIOS

-- ---------------------------------------------------------
-- Catalogo de publicaciones disponibles
-- ---------------------------------------------------------
-- Simula la pantalla principal de la plataforma.
-- Cada fila representa un producto dentro de una publicacion.
-- Solo muestra publicaciones activas y productos disponibles.

CREATE OR REPLACE VIEW vista_usuario_catalogo AS
SELECT
    p.id_publicacion,
    u.nombre AS vendedor,
    p.fecha_hora_inicio,
    p.fecha_hora_fin,

    pr.id_producto,
    pr.nombre AS producto,
    pr.descripcion,

    dp.id_detalle_publicacion,
    dp.precio,
    dp.cantidad_disponible

FROM publicacion p

INNER JOIN usuario u
    ON p.id_vendedor = u.id_usuario

INNER JOIN detalle_publicacion dp
    ON p.id_publicacion = dp.id_publicacion

INNER JOIN producto pr
    ON dp.id_producto = pr.id_producto

WHERE
    p.estado = 'ACTIVA'
    AND dp.estado = 'DISPONIBLE'
    AND dp.cantidad_disponible > 0
    AND NOW() BETWEEN p.fecha_hora_inicio
                  AND p.fecha_hora_fin;


-- ---------------------------------------------------------
-- Detalles de los productos disponibles

-- Simula la pantalla que aparece cuando un usuario
-- selecciona un producto del catalogo.
-- Incluye ingredientes, alergenos e imagenes asociadas.

CREATE OR REPLACE VIEW vista_usuario_detalle_producto AS
SELECT
    c.id_publicacion,
    c.vendedor,
    c.fecha_hora_inicio,
    c.fecha_hora_fin,

    c.id_producto,
    c.producto,
    c.descripcion,

    c.precio,
    c.cantidad_disponible,

    (
        SELECT GROUP_CONCAT(
            pi.ingrediente SEPARATOR ', '
        )
        FROM producto_ingrediente pi
        WHERE pi.id_producto = c.id_producto
    ) AS ingredientes,

    (
        SELECT GROUP_CONCAT(
            pa.alergeno SEPARATOR ', '
        )
        FROM producto_alergeno pa
        WHERE pa.id_producto = c.id_producto
    ) AS alergenos,

    (
        SELECT GROUP_CONCAT(
            ia.archivo SEPARATOR ', '
        )
        FROM imagen i
        INNER JOIN imagen_archivo ia
            ON i.id_imagen = ia.id_imagen
        WHERE i.id_producto = c.id_producto
    ) AS imagenes

FROM vista_usuario_catalogo c;

-- ---------------------------------------------------------
-- 4. PROCEDIMIENTOS PARA OPERACIONES DE USUARIO

DELIMITER $$

CREATE PROCEDURE sp_obtener_usuario_sesion(OUT p_id_usuario INT)
SQL SECURITY DEFINER
READS SQL DATA
BEGIN
 SET p_id_usuario=NULL;
 SELECT id_usuario INTO p_id_usuario
 FROM cuenta_aplicacion
 WHERE usuario_sql=SUBSTRING_INDEX(SESSION_USER(),'@',1)
 LIMIT 1;

 IF p_id_usuario IS NULL THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='La cuenta SQL no esta vinculada a un usuario.';
 END IF;
END$$

CREATE PROCEDURE sp_crear_producto(
 IN p_nombre VARCHAR(100),
 IN p_descripcion TEXT,
 OUT p_id_producto INT
)
SQL SECURITY DEFINER
MODIFIES SQL DATA
BEGIN
 DECLARE v_usuario INT;
 CALL sp_obtener_usuario_sesion(v_usuario);
 INSERT INTO producto(id_usuario,nombre,descripcion)
 VALUES(v_usuario,p_nombre,p_descripcion);
 SET p_id_producto=LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_crear_publicacion(
 IN p_inicio DATETIME,
 IN p_fin DATETIME,
 OUT p_id_publicacion INT
)
SQL SECURITY DEFINER
MODIFIES SQL DATA
BEGIN
 DECLARE v_usuario INT;
 CALL sp_obtener_usuario_sesion(v_usuario);

 IF p_inicio IS NULL OR p_fin IS NULL OR p_fin<=p_inicio THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='El horario de fin debe ser posterior al de inicio.';
 END IF;

 INSERT INTO publicacion(id_vendedor,fecha_hora_inicio,fecha_hora_fin,estado)
 VALUES(v_usuario,p_inicio,p_fin,'BORRADOR');
 SET p_id_publicacion=LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_agregar_producto_publicacion(
 IN p_id_publicacion INT,
 IN p_id_producto INT,
 IN p_precio DECIMAL(10,2),
 IN p_cantidad INT
)
SQL SECURITY DEFINER
MODIFIES SQL DATA
BEGIN
 DECLARE v_usuario INT;
 DECLARE v_vendedor INT DEFAULT NULL;
 DECLARE v_propietario INT DEFAULT NULL;
 DECLARE v_estado VARCHAR(20);

 CALL sp_obtener_usuario_sesion(v_usuario);

 SELECT id_vendedor,estado INTO v_vendedor,v_estado
 FROM publicacion WHERE id_publicacion=p_id_publicacion;

 SELECT id_usuario INTO v_propietario
 FROM producto WHERE id_producto=p_id_producto;

 IF v_vendedor IS NULL OR v_vendedor<>v_usuario THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='No puedes modificar publicaciones de otro vendedor.';
 END IF;

 IF v_propietario IS NULL OR v_propietario<>v_usuario THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='Solo puedes publicar productos registrados por ti.';
 END IF;

 IF v_estado<>'BORRADOR' OR p_precio<0 OR p_cantidad<=0 THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='La publicacion debe estar en borrador y los valores ser validos.';
 END IF;

 INSERT INTO detalle_publicacion
 (id_publicacion,id_producto,precio,cantidad_publicada,cantidad_disponible)
 VALUES(p_id_publicacion,p_id_producto,p_precio,p_cantidad,p_cantidad);
END$$

CREATE PROCEDURE sp_activar_publicacion(IN p_id_publicacion INT)
SQL SECURITY DEFINER
MODIFIES SQL DATA
BEGIN
 DECLARE v_usuario INT;
 DECLARE v_vendedor INT DEFAULT NULL;
 DECLARE v_estado VARCHAR(20);
 DECLARE v_productos INT;

 CALL sp_obtener_usuario_sesion(v_usuario);

 SELECT id_vendedor,estado INTO v_vendedor,v_estado
 FROM publicacion WHERE id_publicacion=p_id_publicacion;

 IF v_vendedor IS NULL OR v_vendedor<>v_usuario OR v_estado<>'BORRADOR' THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='Publicacion inexistente, ajena o no editable.';
 END IF;

 SELECT COUNT(*) INTO v_productos
 FROM detalle_publicacion WHERE id_publicacion=p_id_publicacion;

 IF v_productos=0 THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='Agrega al menos un producto antes de activar.';
 END IF;

 UPDATE publicacion SET estado='ACTIVA'
 WHERE id_publicacion=p_id_publicacion;
END$$

CREATE PROCEDURE sp_editar_producto_publicacion(
 IN p_id_detalle INT,
 IN p_precio DECIMAL(10,2),
 IN p_cantidad_total INT
)
SQL SECURITY DEFINER
MODIFIES SQL DATA
BEGIN
 DECLARE v_usuario INT;
 DECLARE v_vendedor INT DEFAULT NULL;
 DECLARE v_reservado INT DEFAULT 0;

 CALL sp_obtener_usuario_sesion(v_usuario);

 SELECT p.id_vendedor,dp.cantidad_publicada-dp.cantidad_disponible
 INTO v_vendedor,v_reservado
 FROM detalle_publicacion dp
 JOIN publicacion p ON p.id_publicacion=dp.id_publicacion
 WHERE dp.id_detalle_publicacion=p_id_detalle;

 IF v_vendedor IS NULL OR v_vendedor<>v_usuario THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='No puedes editar productos de publicaciones ajenas.';
 END IF;

 IF p_precio<0 OR p_cantidad_total<=0 OR p_cantidad_total<v_reservado THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='Precio o cantidad invalidos; no puede reducirse por debajo de lo reservado.';
 END IF;

 UPDATE detalle_publicacion
 SET precio=p_precio,
     cantidad_publicada=p_cantidad_total,
     cantidad_disponible=p_cantidad_total-v_reservado,
     estado=IF(p_cantidad_total=v_reservado,'AGOTADO','DISPONIBLE')
 WHERE id_detalle_publicacion=p_id_detalle;
END$$

-- Crea una reserva para un producto. Se pueden agregar mas productos
-- de la misma publicacion con sp_agregar_producto_a_reserva.
CREATE PROCEDURE sp_reservar_producto(
 IN p_id_publicacion INT,
 IN p_id_ubicacion INT,
 IN p_id_detalle_publicacion INT,
 IN p_cantidad INT,
 OUT p_id_reserva INT
)
SQL SECURITY DEFINER
MODIFIES SQL DATA
BEGIN
 DECLARE v_comprador INT;
 DECLARE v_estado VARCHAR(20);
 DECLARE v_inicio DATETIME;
 DECLARE v_fin DATETIME;
 DECLARE v_disponible INT;
 DECLARE v_precio DECIMAL(10,2);
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  ROLLBACK;
  RESIGNAL;
 END;

 CALL sp_obtener_usuario_sesion(v_comprador);

 IF p_cantidad<=0 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La cantidad debe ser mayor a cero.';
 END IF;

 START TRANSACTION;

 SELECT estado,fecha_hora_inicio,fecha_hora_fin
 INTO v_estado,v_inicio,v_fin
 FROM publicacion
 WHERE id_publicacion=p_id_publicacion
 FOR UPDATE;

 IF v_estado IS NULL OR v_estado<>'ACTIVA'
    OR NOW()<v_inicio OR NOW()>v_fin THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='La publicacion no esta activa o esta fuera del horario.';
 END IF;

 SELECT cantidad_disponible,precio
 INTO v_disponible,v_precio
 FROM detalle_publicacion
 WHERE id_detalle_publicacion=p_id_detalle_publicacion
   AND id_publicacion=p_id_publicacion
 FOR UPDATE;

 IF v_disponible IS NULL OR v_disponible<p_cantidad THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='Producto no incluido en la publicacion o existencia insuficiente.';
 END IF;

 IF NOT EXISTS(SELECT 1 FROM ubicacion
  WHERE id_ubicacion=p_id_ubicacion AND estado='ACTIVA') THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='La ubicacion no existe o esta inactiva.';
 END IF;

 INSERT INTO reserva(id_comprador,id_publicacion,id_ubicacion,estado)
 VALUES(v_comprador,p_id_publicacion,p_id_ubicacion,'PENDIENTE');

 SET p_id_reserva=LAST_INSERT_ID();

 INSERT INTO detalle_reserva
 (id_reserva,id_publicacion,id_detalle_publicacion,cantidad,precio_unitario)
 VALUES(p_id_reserva,p_id_publicacion,p_id_detalle_publicacion,p_cantidad,v_precio);

 UPDATE detalle_publicacion
 SET cantidad_disponible=cantidad_disponible-p_cantidad,
     estado=IF(cantidad_disponible-p_cantidad=0,'AGOTADO','DISPONIBLE')
 WHERE id_detalle_publicacion=p_id_detalle_publicacion;

 COMMIT;
END$$

CREATE PROCEDURE sp_agregar_producto_a_reserva(
 IN p_id_reserva INT,
 IN p_id_detalle_publicacion INT,
 IN p_cantidad INT
)
SQL SECURITY DEFINER
MODIFIES SQL DATA
BEGIN
 DECLARE v_comprador INT;
 DECLARE v_publicacion INT DEFAULT NULL;
 DECLARE v_estado VARCHAR(20);
 DECLARE v_publicacion_producto INT DEFAULT NULL;
 DECLARE v_disponible INT;
 DECLARE v_precio DECIMAL(10,2);
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  ROLLBACK;
  RESIGNAL;
 END;

 CALL sp_obtener_usuario_sesion(v_comprador);

 IF p_cantidad<=0 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La cantidad debe ser mayor a cero.';
 END IF;

 START TRANSACTION;

 SELECT id_publicacion,estado INTO v_publicacion,v_estado
 FROM reserva
 WHERE id_reserva=p_id_reserva AND id_comprador=v_comprador
 FOR UPDATE;

 IF v_publicacion IS NULL OR v_estado<>'PENDIENTE' THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='La reserva no existe, no te pertenece o no esta pendiente.';
 END IF;

 SELECT id_publicacion,cantidad_disponible,precio
 INTO v_publicacion_producto,v_disponible,v_precio
 FROM detalle_publicacion
 WHERE id_detalle_publicacion=p_id_detalle_publicacion
 FOR UPDATE;

 IF v_publicacion_producto IS NULL OR v_publicacion_producto<>v_publicacion THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='Solo puedes agregar productos de la misma publicacion.';
 END IF;

 IF v_disponible<p_cantidad THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Existencia insuficiente.';
 END IF;

 INSERT INTO detalle_reserva
 (id_reserva,id_publicacion,id_detalle_publicacion,cantidad,precio_unitario)
 VALUES(p_id_reserva,v_publicacion,p_id_detalle_publicacion,p_cantidad,v_precio)
 ON DUPLICATE KEY UPDATE cantidad=cantidad+p_cantidad;

 UPDATE detalle_publicacion
 SET cantidad_disponible=cantidad_disponible-p_cantidad,
     estado=IF(cantidad_disponible-p_cantidad=0,'AGOTADO','DISPONIBLE')
 WHERE id_detalle_publicacion=p_id_detalle_publicacion;

 COMMIT;
END$$

CREATE PROCEDURE sp_cancelar_reserva(IN p_id_reserva INT)
SQL SECURITY DEFINER
MODIFIES SQL DATA
BEGIN
 DECLARE v_comprador INT;
 DECLARE v_estado VARCHAR(20);
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  ROLLBACK;
  RESIGNAL;
 END;

 CALL sp_obtener_usuario_sesion(v_comprador);
 START TRANSACTION;

 SELECT estado INTO v_estado
 FROM reserva
 WHERE id_reserva=p_id_reserva AND id_comprador=v_comprador
 FOR UPDATE;

 IF v_estado IS NULL OR v_estado<>'PENDIENTE' THEN
  SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT='Solo puedes cancelar tus propias reservas pendientes.';
 END IF;

 UPDATE detalle_publicacion dp
 JOIN detalle_reserva dr
  ON dr.id_detalle_publicacion=dp.id_detalle_publicacion
 SET dp.cantidad_disponible=dp.cantidad_disponible+dr.cantidad,
     dp.estado='DISPONIBLE'
 WHERE dr.id_reserva=p_id_reserva;

 UPDATE reserva SET estado='CANCELADA'
 WHERE id_reserva=p_id_reserva;

 COMMIT;
END$$

DELIMITER ;

-- ---------------------------------------------------------
-- 5. ROLES Y USUARIOS MYSQL


-- Se crean tres roles. El administrador recibe todos los privilegios
-- sobre la base y permisos de ejecucion sobre sus procedimientos.
CREATE ROLE IF NOT EXISTS 'rol_administrador';
CREATE ROLE IF NOT EXISTS 'rol_vendedor';
CREATE ROLE IF NOT EXISTS 'rol_comprador';

GRANT ALL PRIVILEGES ON marketplaceupiit.* TO 'rol_administrador';

-- Los vendedores consultan el catalogo y modifican informacion mediante
-- procedimientos que validan que sean propietarios.
GRANT SELECT ON marketplaceupiit.vista_admin_resumen TO 'rol_administrador';
GRANT SELECT ON marketplaceupiit.vista_admin_detalle_operativo TO 'rol_administrador';

GRANT SELECT ON marketplaceupiit.producto TO 'rol_vendedor';
GRANT SELECT ON marketplaceupiit.producto_ingrediente TO 'rol_vendedor';
GRANT SELECT ON marketplaceupiit.producto_alergeno TO 'rol_vendedor';
GRANT SELECT ON marketplaceupiit.imagen TO 'rol_vendedor';
GRANT SELECT ON marketplaceupiit.imagen_archivo TO 'rol_vendedor';
GRANT SELECT ON marketplaceupiit.publicacion TO 'rol_vendedor';
GRANT SELECT ON marketplaceupiit.detalle_publicacion TO 'rol_vendedor';
GRANT SELECT ON marketplaceupiit.vista_admin_detalle_operativo TO 'rol_vendedor';

-- Compradores pueden consultar publicaciones/productos/ubicaciones.
-- Las reservas se crean y modifican por procedimientos.
GRANT SELECT ON marketplaceupiit.publicacion TO 'rol_comprador';
GRANT SELECT ON marketplaceupiit.detalle_publicacion TO 'rol_comprador';
GRANT SELECT ON marketplaceupiit.producto TO 'rol_comprador';
GRANT SELECT ON marketplaceupiit.producto_ingrediente TO 'rol_comprador';
GRANT SELECT ON marketplaceupiit.producto_alergeno TO 'rol_comprador';
GRANT SELECT ON marketplaceupiit.imagen TO 'rol_comprador';
GRANT SELECT ON marketplaceupiit.imagen_archivo TO 'rol_comprador';
GRANT SELECT ON marketplaceupiit.ubicacion TO 'rol_comprador';

GRANT EXECUTE ON PROCEDURE marketplaceupiit.sp_crear_producto TO 'rol_vendedor';
GRANT EXECUTE ON PROCEDURE marketplaceupiit.sp_crear_publicacion TO 'rol_vendedor';
GRANT EXECUTE ON PROCEDURE marketplaceupiit.sp_agregar_producto_publicacion TO 'rol_vendedor';
GRANT EXECUTE ON PROCEDURE marketplaceupiit.sp_activar_publicacion TO 'rol_vendedor';
GRANT EXECUTE ON PROCEDURE marketplaceupiit.sp_editar_producto_publicacion TO 'rol_vendedor';

GRANT EXECUTE ON PROCEDURE marketplaceupiit.sp_reservar_producto TO 'rol_comprador';
GRANT EXECUTE ON PROCEDURE marketplaceupiit.sp_agregar_producto_a_reserva TO 'rol_comprador';
GRANT EXECUTE ON PROCEDURE marketplaceupiit.sp_cancelar_reserva TO 'rol_comprador';

-- Cuentas SQL de demostracion. El usuario admin tiene todos los permisos.
CREATE USER IF NOT EXISTS 'admin_market'@'localhost' IDENTIFIED BY 'AdminDemo_2026!';
CREATE USER IF NOT EXISTS 'juan_app'@'localhost' IDENTIFIED BY 'JuanDemo_2026!';
CREATE USER IF NOT EXISTS 'maria_app'@'localhost' IDENTIFIED BY 'MariaDemo_2026!';
CREATE USER IF NOT EXISTS 'carlos_app'@'localhost' IDENTIFIED BY 'CarlosDemo_2026!';
CREATE USER IF NOT EXISTS 'ana_app'@'localhost' IDENTIFIED BY 'AnaDemo_2026!';

GRANT 'rol_administrador' TO 'admin_market'@'localhost';
GRANT 'rol_vendedor' TO 'juan_app'@'localhost';
GRANT 'rol_vendedor' TO 'maria_app'@'localhost';
GRANT 'rol_comprador' TO 'carlos_app'@'localhost';
GRANT 'rol_comprador' TO 'ana_app'@'localhost';

SET DEFAULT ROLE 'rol_administrador' TO 'admin_market'@'localhost';
SET DEFAULT ROLE 'rol_vendedor' TO 'juan_app'@'localhost','maria_app'@'localhost';
SET DEFAULT ROLE 'rol_comprador' TO 'carlos_app'@'localhost','ana_app'@'localhost';

-- ---------------------------------------------------------
-- 6. DATOS DE DEMOSTRACION


INSERT INTO usuario
(id_usuario,nombre,correo,contrasena_hash,tipo_usuario,estado) VALUES
(1,'Juan Perez','juan@upiit.mx','HASH_DEMO_JUAN','VENDEDOR','ACTIVO'),
(2,'Maria Lopez','maria@upiit.mx','HASH_DEMO_MARIA','VENDEDOR','ACTIVO'),
(3,'Carlos Hernandez','carlos@upiit.mx','HASH_DEMO_CARLOS','COMPRADOR','ACTIVO'),
(4,'Ana Garcia','ana@upiit.mx','HASH_DEMO_ANA','COMPRADOR','ACTIVO'),
(5,'Luis Martinez','luis@upiit.mx','HASH_DEMO_LUIS','AMBOS','ACTIVO'),
(6,'Sofia Ramirez','sofia@upiit.mx','HASH_DEMO_SOFIA','VENDEDOR','ACTIVO'),
(7,'Diego Torres','diego@upiit.mx','HASH_DEMO_DIEGO','COMPRADOR','ACTIVO'),
(8,'Valeria Cruz','valeria@upiit.mx','HASH_DEMO_VALERIA','AMBOS','ACTIVO');

INSERT INTO vendedor(id_usuario) VALUES(1),(2),(5),(6),(8);

INSERT INTO cuenta_aplicacion(usuario_sql,id_usuario) VALUES
('juan_app',1),('maria_app',2),('carlos_app',3),('ana_app',4);

INSERT INTO horario(id_vendedor,dia,hora_inicio,hora_fin) VALUES
(1,'LUNES','10:00','13:00'),
(1,'MIERCOLES','12:00','15:00'),
(2,'MARTES','11:00','14:00'),
(2,'JUEVES','13:00','16:00'),
(5,'VIERNES','10:00','14:00'),
(6,'LUNES','11:00','14:00'),
(8,'MIERCOLES','10:00','13:00');

INSERT INTO producto(id_producto,id_usuario,nombre,descripcion) VALUES
(1,1,'Brownie de chocolate','Brownie casero de chocolate con nuez.'),
(2,1,'Galletas de avena','Galletas de avena con chispas de chocolate.'),
(3,2,'Sandwich de pollo','Sandwich de pollo con lechuga, tomate y aderezo.'),
(4,2,'Agua de limon','Agua fresca de limon preparada el mismo dia.'),
(5,5,'Cupcake de vainilla','Cupcake individual con betun.'),
(6,5,'Panque de platano','Rebanada de panque casero.'),
(7,6,'Ensalada de frutas','Vaso de fruta de temporada.'),
(8,6,'Yogur con granola','Yogur natural con granola.'),
(9,8,'Quesadilla','Quesadilla de queso preparada al momento.'),
(10,8,'Cafe frio','Cafe frio con leche.');

INSERT INTO producto_ingrediente VALUES
(1,'Chocolate'),(1,'Harina'),(1,'Huevo'),(1,'Mantequilla'),(1,'Nuez'),
(2,'Avena'),(2,'Chocolate'),(2,'Harina'),(2,'Mantequilla'),
(3,'Aderezo'),(3,'Lechuga'),(3,'Pan'),(3,'Pollo'),(3,'Tomate'),
(4,'Agua'),(4,'Azucar'),(4,'Limon'),
(5,'Harina'),(5,'Huevo'),(5,'Vainilla'),
(6,'Platano'),(6,'Harina'),(6,'Huevo'),
(7,'Fresa'),(7,'Melon'),(7,'Papaya'),
(8,'Granola'),(8,'Yogur'),
(9,'Queso'),(9,'Tortilla'),
(10,'Cafe'),(10,'Leche');

INSERT INTO producto_alergeno VALUES
(1,'Gluten'),(1,'Huevo'),(1,'Nuez'),
(2,'Gluten'),(2,'Lacteos'),
(3,'Gluten'),(3,'Huevo'),
(5,'Gluten'),(5,'Huevo'),(5,'Lacteos'),
(6,'Gluten'),(6,'Huevo'),
(8,'Lacteos'),(9,'Lacteos'),(10,'Lacteos');

INSERT INTO imagen(id_imagen,id_producto) VALUES
(1,1),(2,2),(3,3),(4,4),(5,5),(6,6),(7,7),(8,8),(9,9),(10,10);

INSERT INTO imagen_archivo(id_imagen,archivo) VALUES
(1,'brownie_chocolate.jpg'),(1,'brownie_detalle.jpg'),
(2,'galletas_avena.jpg'),(3,'sandwich_pollo.jpg'),
(4,'agua_limon.jpg'),(5,'cupcake_vainilla.jpg'),
(6,'panque_platano.jpg'),(7,'ensalada_frutas.jpg'),
(8,'yogur_granola.jpg'),(9,'quesadilla.jpg'),(10,'cafe_frio.jpg');

INSERT INTO ubicacion(id_ubicacion,nombre,descripcion) VALUES
(1,'Edificio de Ingenierias','Entrada principal del edificio.'),
(2,'Cafeteria','Area principal de la cafeteria.'),
(3,'Biblioteca','Entrada de la biblioteca.'),
(4,'Explanada','Explanada central del campus.');

-- Las publicaciones de prueba abarcan el dia actual para poder consultar
-- facilmente el catalogo y las metricas de actividad.
INSERT INTO publicacion
(id_publicacion, id_vendedor, fecha_hora_inicio, fecha_hora_fin, estado) VALUES
(1, 1, TIMESTAMP(CURRENT_DATE(), '00:00:00'), TIMESTAMP(CURRENT_DATE(), '23:59:00'), 'ACTIVA'),
(2, 2, TIMESTAMP(CURRENT_DATE(), '00:00:00'), TIMESTAMP(CURRENT_DATE(), '23:59:00'), 'ACTIVA'),
(3, 5, TIMESTAMP(CURRENT_DATE(), '00:00:00'), TIMESTAMP(CURRENT_DATE(), '23:59:00'), 'ACTIVA'),
(4, 6, TIMESTAMP(CURRENT_DATE(), '00:00:00'), TIMESTAMP(CURRENT_DATE(), '23:59:00'), 'ACTIVA'),
(5, 8, TIMESTAMP(CURRENT_DATE(), '00:00:00'), TIMESTAMP(CURRENT_DATE(), '23:59:00'), 'ACTIVA'),
(6, 1, DATE_ADD(NOW(), INTERVAL 1 DAY),
       DATE_ADD(DATE_ADD(NOW(), INTERVAL 1 DAY), INTERVAL 3 HOUR),
       'BORRADOR');

INSERT INTO detalle_publicacion
(id_detalle_publicacion,id_publicacion,id_producto,precio,cantidad_publicada,cantidad_disponible,estado) VALUES
(1,1,1,25.00,20,15,'DISPONIBLE'),
(2,1,2,15.00,30,25,'DISPONIBLE'),
(3,2,3,40.00,10,8,'DISPONIBLE'),
(4,2,4,18.00,25,20,'DISPONIBLE'),
(5,3,5,22.00,15,12,'DISPONIBLE'),
(6,3,6,20.00,12,10,'DISPONIBLE'),
(7,4,7,30.00,10,8,'DISPONIBLE'),
(8,4,8,28.00,10,7,'DISPONIBLE'),
(9,5,9,18.00,20,18,'DISPONIBLE'),
(10,5,10,25.00,15,14,'DISPONIBLE');

INSERT INTO reserva
(id_reserva,id_comprador,id_publicacion,id_ubicacion,fecha_reserva,estado) VALUES
(1,3,1,1,NOW(),'CONFIRMADA'),
(2,4,1,2,NOW(),'PENDIENTE'),
(3,7,2,3,NOW(),'PENDIENTE'),
(4,3,3,1,NOW(),'COMPLETADA'),
(5,4,4,4,NOW(),'PENDIENTE');

INSERT INTO detalle_reserva
(id_reserva,id_publicacion,id_detalle_publicacion,cantidad,precio_unitario) VALUES
(1,1,1,2,25.00),(1,1,2,3,15.00),
(2,1,1,3,25.00),(2,1,2,2,15.00),
(3,2,3,2,40.00),(3,2,4,5,18.00),
(4,3,5,3,22.00),
(5,4,7,2,30.00),(5,4,8,3,28.00);

-- ---------------------------------------------------------
-- 7. CONSULTAS PARA VERIFICAR LA INSTALACION

SELECT * FROM vista_admin_resumen;
SELECT * FROM vista_admin_detalle_operativo ORDER BY id_publicacion,id_reserva,id_producto;

-- Consultas adicionales que el administrador puede ejecutar:
-- SELECT * FROM vista_admin_detalle_operativo WHERE estado_publicacion='ACTIVA';
-- SELECT * FROM vista_admin_detalle_operativo WHERE estado_reserva='PENDIENTE';
-- SELECT * FROM vista_admin_detalle_operativo WHERE vendedor='Juan Perez';
-- SELECT * FROM vista_admin_detalle_operativo
--  WHERE fecha_reserva >= CURRENT_DATE()
--    AND fecha_reserva < CURRENT_DATE() + INTERVAL 1 DAY;
-- SELECT producto, SUM(cantidad) AS unidades_reservadas
--  FROM vista_admin_detalle_operativo
--  WHERE estado_reserva IN ('PENDIENTE','CONFIRMADA')
--  GROUP BY id_producto,producto;

-- Ejemplos de operaciones:
-- Conectado como juan_app:
-- SET @id_producto=0;
-- CALL sp_crear_producto('Muffin de arandanos','Muffin casero',@id_producto);
-- SET @id_publicacion=0;
-- CALL sp_crear_publicacion(NOW(),DATE_ADD(NOW(),INTERVAL 3 HOUR),@id_publicacion);
-- CALL sp_agregar_producto_publicacion(@id_publicacion,@id_producto,28.00,10);
-- CALL sp_activar_publicacion(@id_publicacion);
--
-- Conectado como carlos_app:
-- SET @id_reserva=0;
-- CALL sp_reservar_producto(1,1,1,2,@id_reserva);
-- CALL sp_agregar_producto_a_reserva(@id_reserva,2,1);
-- CALL sp_cancelar_reserva(@id_reserva);
--