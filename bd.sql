DROP DATABASE IF EXISTS websempere;
DROP DATABASE IF EXISTS wordpress;
DROP USER IF EXISTS'wordpress'@'%';
-- Creamos la base de datos para wordpress
CREATE DATABASE wordpress;
CREATE USER 'wordpress'@'%' IDENTIFIED BY 'wordpress';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';
FLUSH PRIVILEGES;
-- Base de datos para pagina web
CREATE DATABASE websempere;
USE websempere;
-- Login Usuarios
CREATE TABLE creedenciales (
    id_login INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(255),
    contrasenya VARCHAR(255)
);
-- Tabla Usuarios
CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    apellidos VARCHAR(100),
    direccion VARCHAR(255),
    fecha_nac DATE,
    email VARCHAR(255),
    imagen LONGBLOB,
    id_login INT,
    CONSTRAINT id_login FOREIGN KEY (id_login) REFERENCES creedenciales(id_login) ON DELETE RESTRICT ON UPDATE CASCADE
);
-- Tabla categorias
CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255)
);
-- Insertar la categoria "General"
INSERT INTO categorias (nombre) VALUES ('General');
CREATE TABLE incidencias(
    id_incidencia INT AUTO_INCREMENT PRIMARY KEY,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario INT,
    categoria INT,
    descripcion TEXT,
    estado ENUM('pendiente', 'en revision', 'cerrada') DEFAULT 'pendiente',  
    CONSTRAINT id_usuario FOREIGN KEY (usuario) REFERENCES usuarios(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT id_categoria FOREIGN KEY (categoria) REFERENCES categorias(id_categoria) ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE TABLE historico_incidencias(
    id_historio INT AUTO_INCREMENT PRIMARY KEY,
    id_incidencia INT,
    categoria INT,
    usuario INT,
    estado ENUM('cerrada'),
    comentario_cierre VARCHAR(255),
    descripcion VARCHAR(255),
    CONSTRAINT usuario FOREIGN KEY (usuario) REFERENCES usuarios(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT categoria FOREIGN KEY (categoria) REFERENCES categorias(id_categoria) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT id_incidencia FOREIGN KEY (id_incidencia) REFERENCES incidencias(id_incidencia) ON DELETE RESTRICT ON UPDATE CASCADE
);
-- Creacion de Vistas
-- CREATE VIEW 



-- Creacion de platilla permisos para nuestros usuarios
-- Triggers al actualizar el estado a "cerrada"
DELIMITER //
CREATE TRIGGER updateIncidencias
AFTER UPDATE ON incidencias 
FOR EACH ROW
BEGIN
    IF NEW.estado <> OLD.estado AND NEW.estado = 'cerrada' THEN
        INSERT INTO historico_incidencias VALUES (NULL, id_incidencia.OLD, categoria.OLD, usuario.OLD, estado.NEW, comentario_cierre.NEW, descripcion.OLD);
    END IF;
END
//
DELIMITER ;
-- No permeten tenir menys d’una categoria.
DELIMITER //
CREATE TRIGGER asegurarCategoria
BEFORE DELETE ON categorias
FOR EACH ROW
BEGIN
    DECLARE contar_categories INT;
    SELECT COUNT(*) INTO contar_categories FROM categorias;
    IF contar_categories <= 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar la última categoría';
    END IF;
END;
//
DELIMITER ;
/*
-- Validar Login
DELIMITER //
CREATE FUNCTION validarLogin(usuario_var VARCHAR(255), contrasenya_var VARCHAR(255)) RETURNS INT
BEGIN
    DECLARE coindidencia INT;
    DECLARE contrasenya_cifrada VARCHAR(255);

-- Cifrar la contrasenya
    SET contrasenya_cifrada = (SELECT SHA2(contrasenya_var, 256));
    SELECT COUNT(*) INTO coindidencia FROM creedenciales WHERE usuario=usuario_var AND contrasenya=contrasenya_cifrada;    
    IF (coindidencia = 1) THEN
        RETURN 1; -- Indica que el login és vàlid
    ELSE 
        RETURN 0; -- Indica que el login no és vàlid
    END IF;
END
//
DELIMITER ;
*/
/*
-- Crear la función
DELIMITER //
CREATE FUNCTION validar_login(usuario VARCHAR(255), contrasenya VARCHAR(255))
RETURNS BOOLEAN
BEGIN
    DECLARE contrasenya_hash VARCHAR(64);
    SELECT SHA2(contrasenya, 256) INTO contrasenya_hash;

    DECLARE contador INT;
    SELECT COUNT(*) INTO contador FROM usuarios WHERE nombre_usuario = usuario AND contrasenya_hash = contrasenya;

    IF contador = 1 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
//
DELIMITER ;
*/