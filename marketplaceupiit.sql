

-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS marketplace_upiit;

-- Seleccionar la base de datos
USE marketplace_upiit;

CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    contraseña VARCHAR(255) NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'ACTIVO'
);

CREATE TABLE producto (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    id_vendedor INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    ingredientes TEXT,
    alergenos TEXT,
    imagen VARCHAR(255),
    notas TEXT,
    estado VARCHAR(20) DEFAULT 'ACTIVO',

    CONSTRAINT fk_producto_usuario
        FOREIGN KEY (id_vendedor)
        REFERENCES usuario(id_usuario)
);

CREATE TABLE publicacion (
    id_publicacion INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    cantidad_total INT NOT NULL,
    fecha_publicacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NOT NULL,
    estado VARCHAR(20) DEFAULT 'ACTIVA',

    CONSTRAINT fk_publicacion_producto
        FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto)
);

CREATE TABLE ubicacion (
    id_ubicacion INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

CREATE TABLE reserva (
    id_reserva INT AUTO_INCREMENT PRIMARY KEY,
    id_publicacion INT NOT NULL,
    id_comprador INT NOT NULL,
    id_ubicacion INT NOT NULL,
    cantidad INT NOT NULL,
    fecha_reserva DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'PENDIENTE',

    CONSTRAINT fk_reserva_publicacion
        FOREIGN KEY (id_publicacion)
        REFERENCES publicacion(id_publicacion),

    CONSTRAINT fk_reserva_comprador
        FOREIGN KEY (id_comprador)
        REFERENCES usuario(id_usuario),

    CONSTRAINT fk_reserva_ubicacion
        FOREIGN KEY (id_ubicacion)
        REFERENCES ubicacion(id_ubicacion)
);

CREATE TABLE horario_disponibilidad (
    id_horario INT AUTO_INCREMENT PRIMARY KEY,
    id_vendedor INT NOT NULL,
    dia VARCHAR(20) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,

    CONSTRAINT fk_horario_usuario
        FOREIGN KEY (id_vendedor)
        REFERENCES usuario(id_usuario)
);

DESCRIBE usuario;
DESCRIBE producto;
DESCRIBE publicacion;
DESCRIBE reserva;
DESCRIBE ubicacion;
DESCRIBE horario_disponibilidad;