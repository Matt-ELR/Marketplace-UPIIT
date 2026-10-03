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



-- DATOS DE PRUEBA


USE marketplaceupiit;



-- USUARIOS


INSERT INTO usuario
    (id_usuario, nombre, correo, contraseña, tipo_usuario, estado)
VALUES
    (1, 'Juan Perez', 'juan@upiit.mx', '123456', 'VENDEDOR', 'ACTIVO'),
    (2, 'Maria Lopez', 'maria@upiit.mx', '123456', 'VENDEDOR', 'ACTIVO'),
    (3, 'Carlos Hernandez', 'carlos@upiit.mx', '123456', 'COMPRADOR', 'ACTIVO'),
    (4, 'Ana Garcia', 'ana@upiit.mx', '123456', 'COMPRADOR', 'ACTIVO'),
    (5, 'Luis Martinez', 'luis@upiit.mx', '123456', 'COMPRADOR', 'ACTIVO');



-- VENDEDORES
-- Especialización de USUARIO


INSERT INTO vendedor
    (id_usuario)
VALUES
    (1),
    (2);



-- HORARIOS
-- Relación VENDEDOR - HORARIO


INSERT INTO horario
    (id_horario, id_vendedor, dia, hora_inicio, hora_fin)
VALUES
    (1, 1, 'Lunes',    '10:00:00', '13:00:00'),
    (2, 1, 'Miercoles','12:00:00', '15:00:00'),
    (3, 2, 'Martes',   '11:00:00', '14:00:00'),
    (4, 2, 'Jueves',   '13:00:00', '16:00:00');



-- PRODUCTOS


INSERT INTO producto
    (id_producto, nombre, descripcion)
VALUES
    (1, 'Brownie de chocolate',
     'Brownie de chocolate casero con nuez.'),

    (2, 'Galletas de avena',
     'Galletas de avena con chispas de chocolate.'),

    (3, 'Sandwich de pollo',
     'Sandwich de pollo con lechuga, tomate y aderezo.');



-- INGREDIENTES DE LOS PRODUCTOS


INSERT INTO producto_ingrediente
    (id_producto, ingrediente)
VALUES
    (1, 'Chocolate'),
    (1, 'Harina'),
    (1, 'Huevo'),
    (1, 'Mantequilla'),
    (1, 'Nuez'),

    (2, 'Avena'),
    (2, 'Harina'),
    (2, 'Mantequilla'),
    (2, 'Chocolate'),

    (3, 'Pan'),
    (3, 'Pollo'),
    (3, 'Lechuga'),
    (3, 'Tomate'),
    (3, 'Aderezo');


-- ALERGENOS DE LOS PRODUCTOS

INSERT INTO producto_alergeno
    (id_producto, alergeno)
VALUES
    (1, 'Nuez'),
    (1, 'Gluten'),
    (1, 'Huevo'),

    (2, 'Gluten'),
    (2, 'Lacteos'),

    (3, 'Gluten'),
    (3, 'Huevo');


-- IMAGENES

INSERT INTO imagen
    (id_imagen, id_producto)
VALUES
    (1, 1),
    (2, 2),
    (3, 3);


-- ARCHIVOS DE LAS IMAGENES

INSERT INTO imagen_archivo
    (id_imagen, archivo)
VALUES
    (1, 'brownie_chocolate.jpg'),
    (1, 'brownie_chocolate_2.jpg'),
    (2, 'galletas_avena.jpg'),
    (3, 'sandwich_pollo.jpg');


-- UBICACIONES

INSERT INTO ubicacion
    (id_ubicacion, nombre, descripcion)
VALUES
    (1, 'Edificio de Ingenierias',
     'Entrada principal del edificio.'),

    (2, 'Cafeteria',
     'Area principal de la cafeteria.'),

    (3, 'Biblioteca',
     'Entrada de la biblioteca del campus.');


-- PUBLICACIONES

INSERT INTO publicacion
    (id_publicacion, id_vendedor, id_producto, precio,
     cantidad_disponible, estado, fecha_publicacion)
VALUES
    (1, 1, 1, 25.00, 20, 'ACTIVA', '2026-10-02 09:00:00'),

    (2, 1, 2, 15.00, 30, 'ACTIVA', '2026-10-02 09:30:00'),

    (3, 2, 3, 40.00, 10, 'ACTIVA', '2026-10-02 10:00:00');


-- RESERVAS

INSERT INTO reserva
    (id_reserva, id_comprador, id_publicacion, id_ubicacion,
     fecha_reserva, cantidad, estado)
VALUES
    (1, 3, 1, 1,
     '2026-10-02 10:30:00', 2, 'CONFIRMADA'),

    (2, 4, 1, 2,
     '2026-10-02 11:00:00', 3, 'PENDIENTE'),

    (3, 5, 2, 3,
     '2026-10-02 11:30:00', 5, 'COMPLETADA'),

    (4, 3, 3, 1,
     '2026-10-02 12:00:00', 1, 'PENDIENTE');