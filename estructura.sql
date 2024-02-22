/*////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////// DDL ///////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////// */
-- Comprobamos si las base de datos estan creadas, si lo estan las elimina
DROP DATABASE IF EXISTS websempere;
DROP DATABASE IF EXISTS wordpress;
-- Comprueba si hay un usuario, si esta lo borra
DROP USER IF EXISTS'wordpress'@'%';
DROP USER IF EXISTS'trabajador'@'%';
DROP USER IF EXISTS'admin'@'%';
-- Creamos la base de datos para wordpress
CREATE DATABASE wordpress;
-- Creamos el usuario que administrara la base de datos de wordpress y le asignamos los permisos

CREATE USER 'wordpress'@'%' IDENTIFIED BY 'wordpress';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';
FLUSH PRIVILEGES;

-- Base de datos para la parte privada Pagina Web Incidencias
CREATE DATABASE websempere;
USE websempere;
-- Creamos las Tablas y sus relaciones entre ellas
-- Login Usuarios
CREATE TABLE creedenciales (
    id_login INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(255) UNIQUE NOT NULL,
    contrasenya VARCHAR(255),
    rol ENUM('admin', 'trabajador') DEFAULT 'trabajador'
);

-- Tabla Usuarios
CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    apellidos VARCHAR(100),
    direccion VARCHAR(255),
    fecha_nac DATE,
    email VARCHAR(255),
    imagen VARCHAR(255) DEFAULT 'http://30.40.40.13/media/imagenesPerfiles/porDefecto.png', -- Guardarem la URL de la imatge
    id_login INT,
    CONSTRAINT id_login FOREIGN KEY (id_login) REFERENCES creedenciales(id_login) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabla categorias
CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) DEFAULT 'General'
);
-- Tabla de las incidencias
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

-- Tabla del historial de incidencias marcadas como cerradas
CREATE TABLE historico_incidencias(
    id_historio INT AUTO_INCREMENT PRIMARY KEY,
    id_incidencia INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    categoria INT,
    usuario INT,
    estado ENUM('cerrada'),
    descripcion VARCHAR(255),
    CONSTRAINT usuario FOREIGN KEY (usuario) REFERENCES usuarios(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT categoria FOREIGN KEY (categoria) REFERENCES categorias(id_categoria) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT id_incidencia FOREIGN KEY (id_incidencia) REFERENCES incidencias(id_incidencia) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabla que registra todas las consultas realizadas a la base de datos
CREATE TABLE consultas (
    id_consulta INT AUTO_INCREMENT PRIMARY KEY,
    texto_consulta TEXT,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_login INT,
    CONSTRAINT fk_id_login FOREIGN KEY (id_login) REFERENCES creedenciales (id_login) ON DELETE RESTRICT ON UPDATE CASCADE
);
-- Creacion de Vistas
-- Para el administrador
CREATE VIEW vista_administradores AS
SELECT 
    u.id_usuario,
    u.nombre,
    u.apellidos,
    u.direccion,
    u.fecha_nac,
    u.email,
    u.imagen,
    c.id_login,
    c.usuario,
    c.rol,
    i.id_incidencia,
    i.fecha,
    i.descripcion,
    i.estado,
    ic.nombre AS categoria
FROM usuarios u
JOIN creedenciales c ON u.id_login = c.id_login
LEFT JOIN incidencias i ON u.id_usuario = i.usuario
LEFT JOIN categorias ic ON i.categoria = ic.id_categoria;

-- Para los trabajadores
CREATE VIEW vista_trabajadores AS
SELECT 
    u.id_usuario,
    u.nombre,
    u.apellidos,
    u.direccion,
    u.fecha_nac,
    u.email,
    u.imagen,
    c.usuario,
    c.rol,
    i.id_incidencia,
    i.fecha,
    i.descripcion,
    i.estado,
    ic.nombre AS categoria
FROM usuarios u
JOIN creedenciales c ON u.id_login = c.id_login
LEFT JOIN incidencias i ON u.id_usuario = i.usuario
LEFT JOIN categorias ic ON i.categoria = ic.id_categoria;

/*////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////// DDL Avanzado ///////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////// */
/* FUNCIONES */
-- Utilizaremos una funcion que nos cifrara el texto plano a SHA2
DELIMITER //
CREATE FUNCTION cifrarContrasenya(plain_password VARCHAR(255)) RETURNS VARCHAR(64)
    DETERMINISTIC
    NO SQL
    BEGIN
        DECLARE encrypted_password VARCHAR(64);
        SET encrypted_password = SHA2(plain_password, 256);
        RETURN encrypted_password;
    END;
//
DELIMITER ;
-- SELECT cifrarContrasenya('mi_contrasenya');
-- Validar Login
DELIMITER //
CREATE FUNCTION validarLogin(usuario VARCHAR(255), contrasenya VARCHAR(255)) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE existe_usuario INT;    
    -- Verificar si el usuario y la contraseña coinciden en la tabla de credenciales
    SELECT COUNT(*) INTO existe_usuario FROM creedenciales WHERE usuario = usuario AND contrasenya = cifrarContrasenya(contrasenya);    
    -- Si existe al menos un usuario con las credenciales proporcionadas, devuelve TRUE
    IF existe_usuario > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
//
DELIMITER ;

/* PROCEDIMIENTOS */
-- Hemos creado un procedimiento que insertara algunos registros a la tabla usuarios
DELIMITER //
CREATE PROCEDURE insertarUsuarios()
BEGIN
    INSERT INTO creedenciales (usuario, contrasenya, rol) VALUES 
    ('mvalles', '1234', 'admin'),
    ('senguix', '1234', 'trabajador'),
    ('apenades', '1234', 'admin'),
    ('bernat', '1234', 'trabajador'),
    ('juanjo', '1234', 'trabajador');

    -- Insertamos algunos usuarios uniendolos a las creedenciales anteriores
    INSERT INTO usuarios (nombre, apellidos, direccion, fecha_nac, email, id_login)
    VALUES 
    ('Marta', 'Vallés Terol', 'Calle Principal 123', '2004-03-12', 'mvallesterol12@gmail.com', 1),
    ('Sergi', 'Enguix', 'Avenida Central 456', '2003-05-17', 'serenpex@gmail.com', 2),
    ('Alex', 'Penades Soler', 'Plaza Mayor 789', '2002-07-20', 'penadessoler@gmail.com', 3),
    ('Bernat', '', 'Plaza España 67', '2001-07-20', 'tibubernat@gmail.com', 4),
    ('Juanjo', 'Cabello Gutierrez', 'Avenida 7', '1986-07-20', 'juanjosecabellogutierrez@gmail.com', 5);
END //
DELIMITER ;

/* TRIGGERS */
-- Al actualizar el estado a "cerrada" se añade la incidencia al historial
DELIMITER //
    CREATE TRIGGER  añadirIncidenciaAlHistorial
    AFTER UPDATE ON incidencias 
    FOR EACH ROW
    BEGIN
        IF NEW.estado <> OLD.estado AND NEW.estado = 'cerrada' THEN
            INSERT INTO historico_incidencias 
            VALUES (NULL, NEW.id_incidencia, CURRENT_TIMESTAMP, NEW.categoria, NEW.usuario, NEW.estado, NEW.descripcion);
            -- DELETE FROM incidencias WHERE id_incidencia = NEW.id_incidencia;
        END IF;
    END
//
DELIMITER ;
-- Actualizar la fecha de la incidencia al actualizar el estado de esta
DELIMITER //
    CREATE TRIGGER actualizar_fecha
    BEFORE UPDATE ON incidencias
    FOR EACH ROW
    BEGIN
        SET NEW.fecha = CURRENT_TIMESTAMP;
    END;
    //
DELIMITER ;
-- No nos va a permitir tener menos de una categoria y no se podra eliminar la categoria general
DELIMITER //
    CREATE TRIGGER asegurarCategoria
    BEFORE DELETE ON categorias
    FOR EACH ROW
    BEGIN
        DECLARE contar_categories INT;
        -- Verificar si la categoría que se intenta eliminar es la última categoría
        SELECT COUNT(*) INTO contar_categories FROM categorias;    
        IF contar_categories <= 1 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar la última categoría';
        END IF;
        -- Verificar si la categoría que se intenta eliminar es la última categoría General ya que es la de Por Defecto
        IF OLD.nombre = 'General' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar la categoría General.';
        END IF;
    END;
//
DELIMITER ;
-- Antes de crear un nuevo login cifrara la contrasenya en texto plano guardando-la en la tabla
DELIMITER //
    CREATE TRIGGER antesInsertarLogin
    BEFORE INSERT ON creedenciales
    FOR EACH ROW
    BEGIN
        SET NEW.contrasenya = cifrarContrasenya(NEW.contrasenya);
    END
    //
DELIMITER ;
-- Si se actualiza la contraseña salta el disparador para volverla a cifrar
DELIMITER //
CREATE TRIGGER cifrar_contraseña_actualizar
BEFORE UPDATE ON creedenciales
FOR EACH ROW
BEGIN
    IF NEW.contrasenya != OLD.contrasenya THEN
        SET NEW.contrasenya = SHA2(NEW.contrasenya, 256);
    END IF;
END;
//
DELIMITER ;
-- Listado de Consultas ejecutadas
/*
DELIMITER //
CREATE TRIGGER registro_consultas_realizadas
AFTER INSERT ON websempere.*
FOR EACH ROW
BEGIN
    INSERT INTO consultas (texto_consulta) VALUES (NEW.texto_consulta);
END;
// 
DELIMITER ;
*/
/*////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////// DCL ///////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////// */
-- Hemos intentado crear roles pero resulta que solo es valido en MariaDB i estamos utilizando MySQL
-- Cremos los usuarios trabajador y admin
CREATE USER 'trabajador'@'%' IDENTIFIED BY 'Usuario123';
CREATE USER 'admin'@'%' IDENTIFIED BY 'Sempere4';
-- Assignamos los permisos sobre las tablas
-- Permisos Trabajador
GRANT SELECT, UPDATE, INSERT ON websempere.incidencias TO 'trabajador'@'%';
GRANT SELECT, UPDATE ON websempere.creedenciales TO 'trabajador'@'%';
GRANT SELECT, UPDATE ON websempere.usuarios TO 'trabajador'@'%';
-- Permisos Administrador
GRANT ALL PRIVILEGES ON websempere.* TO 'admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
/*////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////// DML ///////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////// */
-- Insertaremos algunos registros en determinadas tablas
-- Categorias
INSERT INTO categorias (nombre) VALUES 
('General'),
('Servidor'),
('Cliente');

-- Llamamos al procedimiento para que inserte los datos de los usuarios
CALL insertarUsuarios();