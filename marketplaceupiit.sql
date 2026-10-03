-- BASE DE DATOS: marketplaceupiit

CREATE DATABASE IF NOT EXISTS marketplaceupiit;

USE marketplaceupiit;



-- ENTIDAD: USUARIO


CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    contraseña VARCHAR(255) NOT NULL,
    tipo_usuario VARCHAR(30),
    estado VARCHAR(20) DEFAULT 'ACTIVO'
);



-- ENTIDAD: VENDEDOR
--
-- VENDEDOR es una especialización de USUARIO.
-- id_usuario es PK y FK al mismo tiempo.
--
-- Relación:
-- USUARIO 1 : 0..1 VENDEDOR


CREATE TABLE vendedor (
    id_usuario INT PRIMARY KEY,

    CONSTRAINT fk_vendedor_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ENTIDAD: HORARIO
--
-- Relación:
-- VENDEDOR 1 : N HORARIO


CREATE TABLE horario (
    id_horario INT AUTO_INCREMENT PRIMARY KEY,
    id_vendedor INT NOT NULL,
    dia VARCHAR(20) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,

    CONSTRAINT fk_horario_vendedor
        FOREIGN KEY (id_vendedor)
        REFERENCES vendedor(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ENTIDAD: PRODUCTO


CREATE TABLE producto (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);



-- ATRIBUTO MULTIVALUADO: INGREDIENTES
--
-- PRODUCTO puede tener varios ingredientes.


CREATE TABLE producto_ingrediente (
    id_producto INT NOT NULL,
    ingrediente VARCHAR(100) NOT NULL,

    PRIMARY KEY (id_producto, ingrediente),

    CONSTRAINT fk_ingrediente_producto
        FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ATRIBUTO MULTIVALUADO: ALERGENO
--
-- PRODUCTO puede tener varios alérgenos.


CREATE TABLE producto_alergeno (
    id_producto INT NOT NULL,
    alergeno VARCHAR(100) NOT NULL,

    PRIMARY KEY (id_producto, alergeno),

    CONSTRAINT fk_alergeno_producto
        FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ENTIDAD: IMAGEN
--
-- Relación:
-- PRODUCTO 1 : N IMAGEN


CREATE TABLE imagen (
    id_imagen INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,

    CONSTRAINT fk_imagen_producto
        FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ATRIBUTO MULTIVALUADO: ARCHIVO
--
-- Una imagen puede tener uno o varios archivos según el modelo.


CREATE TABLE imagen_archivo (
    id_imagen INT NOT NULL,
    archivo VARCHAR(255) NOT NULL,

    PRIMARY KEY (id_imagen, archivo),

    CONSTRAINT fk_archivo_imagen
        FOREIGN KEY (id_imagen)
        REFERENCES imagen(id_imagen)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ENTIDAD: PUBLICACION
--
-- Relaciones:
-- VENDEDOR 1 : N PUBLICACION
-- PRODUCTO 1 : N PUBLICACION


CREATE TABLE publicacion (
    id_publicacion INT AUTO_INCREMENT PRIMARY KEY,
    id_vendedor INT NOT NULL,
    id_producto INT NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    cantidad_disponible INT NOT NULL,
    estado VARCHAR(20) DEFAULT 'ACTIVA',
    fecha_publicacion DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_publicacion_vendedor
        FOREIGN KEY (id_vendedor)
        REFERENCES vendedor(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_publicacion_producto
        FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);



-- ENTIDAD: UBICACION


CREATE TABLE ubicacion (
    id_ubicacion INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);



-- ENTIDAD: RESERVA
--
-- Relación:
-- USUARIO 1 : N RESERVA
--
-- También se relaciona con PUBLICACION y UBICACION.


CREATE TABLE reserva (
    id_reserva INT AUTO_INCREMENT PRIMARY KEY,
    id_comprador INT NOT NULL,
    id_publicacion INT NOT NULL,
    id_ubicacion INT NOT NULL,
    fecha_reserva DATETIME DEFAULT CURRENT_TIMESTAMP,
    cantidad INT NOT NULL,
    estado VARCHAR(20) DEFAULT 'PENDIENTE',

    CONSTRAINT fk_reserva_comprador
        FOREIGN KEY (id_comprador)
        REFERENCES usuario(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_reserva_publicacion
        FOREIGN KEY (id_publicacion)
        REFERENCES publicacion(id_publicacion)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_reserva_ubicacion
        FOREIGN KEY (id_ubicacion)
        REFERENCES ubicacion(id_ubicacion)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);