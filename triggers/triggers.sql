 5. Triggers


1. Actualizar la fecha de modificación de un producto
"Como desarrollador, deseo un trigger que actualice la fecha de modificación cuando se actualice un producto."

🧠 Explicación: Cada vez que se actualiza un producto, queremos que el campo updated_at se actualice automáticamente con la fecha actual (NOW()), sin tener que hacerlo manualmente desde la app.

🔁 Se usa un BEFORE UPDATE.

ALTER TABLE products
ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

DELIMITER //

CREATE TRIGGER trg_products_before_update
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END //

DELIMITER ;

INSERT INTO products (name, detail, price, category_id, image)
VALUES ('Ejemplo Producto', 'Detalle del producto', 10.50, 1, 'imagen.jpg');

UPDATE products
SET price = 12.00
WHERE name = 'Ejemplo Producto';

SELECT id, name, price, updated_at FROM products WHERE name = 'Ejemplo Producto';

2. Registrar log cuando un cliente califica un producto
"Como administrador, quiero un trigger que registre en log cuando un cliente califica un producto."

🧠 Explicación: Cuando alguien inserta una fila en rates, el trigger crea automáticamente un registro en log_acciones con la información del cliente y producto calificado.

🔁 Se usa un AFTER INSERT sobre rates.

CREATE TABLE IF NOT EXISTS log_acciones (
    id INT PRIMARY KEY AUTO_INCREMENT,
    accion_tipo VARCHAR(50) NOT NULL,
    fecha_accion DATETIME DEFAULT CURRENT_TIMESTAMP,
    customer_id INT,
    product_id INT,
    company_id VARCHAR(20),
    descripcion TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (company_id) REFERENCES companies(id)
);

DELIMITER //

CREATE TRIGGER trg_log_product_rating
AFTER INSERT ON quality_products
FOR EACH ROW
BEGIN
 
    INSERT INTO log_acciones (accion_tipo, customer_id, product_id, company_id, descripcion)
    VALUES (
        'Calificación de Producto',
        NEW.customer_id,
        NEW.product_id,
        NEW.company_id,
        CONCAT('El cliente ', NEW.customer_id, ' calificó el producto ', NEW.product_id, ' de la empresa ', NEW.company_id, ' con un rating de ', NEW.rating)
    );
END //

DELIMITER ;

INSERT INTO quality_products (product_id, customer_id, poll_id, company_id, daterating, rating)
VALUES (1, 101, 1, 'COMP001', NOW(), 4.5);

SELECT * FROM log_acciones;

3. Impedir insertar productos sin unidad de medida
"Como técnico, deseo un trigger que impida insertar productos sin unidad de medida."

🧠 Explicación: Antes de guardar un nuevo producto, el trigger revisa si unit_id es NULL. Si lo es, lanza un error con SIGNAL.

🔁 Se usa un BEFORE INSERT.

no pude hacerlo..


 4. Validar calificaciones no mayores a 5
"Como auditor, quiero un trigger que verifique que las calificaciones no superen el valor máximo permitido."

🧠 Explicación: Si alguien intenta insertar una calificación de 6 o más, se bloquea automáticamente. Esto evita errores o trampa.

🔁 Se usa un BEFORE INSERT.

DELIMITER //

CREATE TRIGGER trg_quality_products_before_insert_rating_check
BEFORE INSERT ON quality_products
FOR EACH ROW
BEGIN
    IF NEW.rating > 5.0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La calificación no puede ser mayor a 5.0. Por favor, ingrese un valor válido.';
    END IF;
END //

DELIMITER ;

INSERT INTO quality_products (product_id, customer_id, poll_id, company_id, daterating, rating)
VALUES (1, 101, 1, 'COMP001', NOW(), 4.0);

INSERT INTO quality_products (product_id, customer_id, poll_id, company_id, daterating, rating)
VALUES (1, 102, 1, 'COMP001', NOW(), 6.0);


5. Actualizar estado de membresía cuando vence
"Como supervisor, deseo un trigger que actualice automáticamente el estado de membresía al vencer el periodo."

🧠 Explicación: Cuando se actualiza un periodo de membresía (membershipperiods), si end_date ya pasó, se puede cambiar el campo status a 'INACTIVA'.

🔁 AFTER UPDATE o BEFORE UPDATE dependiendo de la lógica.


DELIMITER //

CREATE TRIGGER trg_customer_memberships_before_update_status
BEFORE UPDATE ON customer_memberships
FOR EACH ROW
BEGIN
    IF NEW.end_date < CURDATE() THEN
        SET NEW.isactive = FALSE;
    END IF;

  END //

DELIMITER ;

INSERT INTO customer_memberships (customer_id, membership_id, start_date, end_date, isactive)
VALUES (1, 1, '2025-01-01', '2025-12-31', TRUE);

INSERT INTO customer_memberships (customer_id, membership_id, start_date, end_date, isactive)
VALUES (2, 1, '2024-01-01', '2024-06-30', TRUE);

UPDATE customer_memberships
SET start_date = '2024-01-01' 
WHERE customer_id = 2 AND membership_id = 1;

SELECT customer_id, membership_id, start_date, end_date, isactive
FROM customer_memberships
WHERE customer_id = 2 AND membership_id = 1;

6. Evitar duplicados de productos por empresa
"Como operador, quiero un trigger que evite duplicar productos por nombre dentro de una misma empresa."

🧠 Explicación: Antes de insertar un nuevo producto en companyproducts, el trigger puede consultar si ya existe uno con el mismo product_id y company_id.

🔁 BEFORE INSERT.

no pude.

7. Enviar notificación al añadir un favorito
"Como cliente, deseo un trigger que envíe notificación cuando añado un producto como favorito."

🧠 Explicación: Después de un INSERT en details_favorites, el trigger agrega un mensaje a una tabla notificaciones.

🔁 AFTER INSERT.

no pude........   


8. Insertar fila en quality_products tras calificación
"Como técnico, quiero un trigger que inserte una fila en quality_products cuando se registra una calificación."

🧠 Explicación: Al insertar una nueva calificación en rates, se crea automáticamente un registro en quality_products para mantener métricas de calidad.

🔁 AFTER INSERT.

ALTER TABLE rates
ADD COLUMN product_id INT(11),
ADD CONSTRAINT fk_rates_product FOREIGN KEY (product_id) REFERENCES products(id);

DELIMITER //

CREATE TRIGGER trg_after_product_quality_insert
AFTER INSERT ON quality_products
FOR EACH ROW
BEGIN
   
    INSERT INTO resumen_calificaciones (empresa_id, mes, año, promedio_calificacion, total_calificaciones, fecha_generacion)
    VALUES (
        NEW.company_id,
        MONTH(NEW.daterating),
        YEAR(NEW.daterating),
        NEW.rating, 1,          
        NOW()
    )
    ON DUPLICATE KEY UPDATE
        promedio_calificacion = (promedio_calificacion * total_calificaciones + NEW.rating) / (total_calificaciones + 1),
        total_calificaciones = total_calificaciones + 1,
        fecha_generacion = NOW();

   

END //

DELIMITER ;

9. Eliminar favoritos si se elimina el producto
"Como desarrollador, deseo un trigger que elimine los favoritos si se elimina el producto."

🧠 Explicación: Cuando se borra un producto, el trigger elimina las filas en details_favorites donde estaba ese producto.

🔁 AFTER DELETE en products.

DELIMITER //

CREATE TRIGGER trg_delete_favorites_on_product_delete
AFTER DELETE ON products
FOR EACH ROW
BEGIN
    DELETE FROM details_favorites
    WHERE product_id = OLD.id;
END //

DELIMITER ;

DELETE FROM products WHERE id = 10;


SELECT * FROM details_favorites WHERE product_id = 10;

10. Bloquear modificación de audiencias activas
"Como administrador, quiero un trigger que bloquee la modificación de audiencias activas."

🧠 Explicación: Si un usuario intenta modificar una audiencia que está en uso, el trigger lanza un error con SIGNAL.

🔁 BEFORE UPDATE.

DELIMITER //

CREATE TRIGGER trg_audiences_before_update_check_in_use
BEFORE UPDATE ON audiences
FOR EACH ROW
BEGIN
    DECLARE is_in_use BOOLEAN DEFAULT FALSE;

   SELECT TRUE INTO is_in_use
    FROM companies
    WHERE audience_id = OLD.id
    LIMIT 1;

     IF NOT is_in_use THEN
        SELECT TRUE INTO is_in_use
        FROM customers
        WHERE audience_id = OLD.id
        LIMIT 1;
    END IF;
 - IF NOT is_in_use THEN
        SELECT TRUE INTO is_in_use
        FROM membershipbenefits
        WHERE audience_id = OLD.id
        LIMIT 1;
    END IF;
 IF NOT is_in_use THEN
        SELECT TRUE INTO is_in_use
        FROM audiencebenefits
        WHERE audience_id = OLD.id
        LIMIT 1;
    END IF;

 
    IF is_in_use THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede modificar esta audiencia porque está actualmente en uso en el sistema (vinculada a empresas, clientes o beneficios).';
    END IF;
END //

DELIMITER ;

INSERT INTO audiences (id, description) VALUES (10, 'Audiencia Activa');
INSERT INTO audiences (id, description) VALUES (11, 'Audiencia Inactiva');

UPDATE companies SET audience_id = 10 WHERE id = 'EMP001';

UPDATE customers SET audience_id = 10 WHERE id = 1;

UPDATE audiences SET description = 'Audiencia Disponible' WHERE id = 11;

UPDATE audiences SET description = 'Audiencia Muy Activa' WHERE id = 10;

 11. Recalcular promedio de calidad del producto tras nueva evaluación
"Como gestor, deseo un trigger que actualice el promedio de calidad del producto tras una nueva evaluación."

🧠 Explicación: Después de insertar en rates, el trigger actualiza el campo average_rating del producto usando AVG().

🔁 AFTER INSERT.

ALTER TABLE products
ADD COLUMN average_rating DOUBLE(10,2) DEFAULT 0.00;


DELIMITER $$

CREATE TRIGGER trg_recalculate_product_avg_rating
AFTER INSERT ON quality_products
FOR EACH ROW
BEGIN
    -- Recalcula el promedio de calificación para el producto afectado
    -- y actualiza la tabla 'products'
    UPDATE products
    SET average_rating = (
        SELECT AVG(rating)
        FROM quality_products
        WHERE product_id = NEW.product_id
    )
    WHERE id = NEW.product_id;
END$$

DELIMITER ;

12. Registrar asignación de nuevo beneficio
"Como auditor, quiero un trigger que registre cada vez que se asigna un nuevo beneficio."

🧠 Explicación: Cuando se hace INSERT en membershipbenefits o audiencebenefits, se agrega un log en bitacora.

CREATE TABLE bitacora (
    id INT PRIMARY KEY AUTO_INCREMENT,
    event_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(50) NOT NULL,
    event_description TEXT
);

DELIMITER $$

CREATE TRIGGER trg_log_membership_benefit_assignment
AFTER INSERT ON membershipbenefits
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (table_name, event_description)
    VALUES (
        'membershipbenefits',
        CONCAT(
            'Nuevo beneficio asignado: ',
            'Membresía ID = ', NEW.membership_id,
            ', Período ID = ', NEW.period_id,
            ', Audiencia ID = ', NEW.audience_id,
            ', Beneficio ID = ', NEW.benefit_id
        )
    );
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_log_audience_benefit_assignment
AFTER INSERT ON audiencebenefits
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (table_name, event_description)
    VALUES (
        'audiencebenefits',
        CONCAT(
            'Nuevo beneficio asignado directamente a audiencia: ',
            'Audiencia ID = ', NEW.audience_id,
            ', Beneficio ID = ', NEW.benefit_id
        )
    );
END$$

DELIMITER ;

13. Impedir doble calificación por parte del cliente
"Como cliente, deseo un trigger que me impida calificar el mismo producto dos veces seguidas."

🧠 Explicación: Antes de insertar en rates, el trigger verifica si ya existe una calificación de ese customer_id y product_id.

DELIMITER $$

CREATE TRIGGER trg_prevent_duplicate_product_rating
BEFORE INSERT ON quality_products
FOR EACH ROW
BEGIN
    DECLARE existing_rating_count INT;

    -- Check if a rating already exists for this customer and product
    SELECT COUNT(*)
    INTO existing_rating_count
    FROM quality_products
    WHERE customer_id = NEW.customer_id
      AND product_id = NEW.product_id;

    -- If a rating already exists, prevent the insert and raise an error
    IF existing_rating_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Este cliente ya ha calificado este producto anteriormente.';
    END IF;
END$$

DELIMITER ;

14. Validar correos duplicados en clientes
"Como técnico, quiero un trigger que valide que el email del cliente no se repita."

🧠 Explicación: Verifica, antes del INSERT, si el correo ya existe en la tabla customers. Si sí, lanza un error.

DELIMITER $$

CREATE TRIGGER trg_validate_customer_email_duplicate
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    DECLARE email_exists INT;

    -- Check if an email already exists
    SELECT COUNT(*)
    INTO email_exists
    FROM customers
    WHERE email = NEW.email;

    -- If the email exists, prevent the insert and raise a custom error
    IF email_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El correo electrónico proporcionado ya está registrado para otro cliente.';
    END IF;
END$$

DELIMITER ;


15. Eliminar detalles de favoritos huérfanos
"Como operador, deseo un trigger que elimine registros huérfanos de details_favorites."

🧠 Explicación: Si se elimina un registro de favorites, se borran automáticamente sus detalles asociados.


ALTER TABLE details_favorites
DROP FOREIGN KEY your_constraint_name;


ALTER TABLE details_favorites
ADD CONSTRAINT fk_details_favorites_favorites 
FOREIGN KEY (favorite_id) REFERENCES favorites(id)
ON DELETE CASCADE;

DELIMITER $$

CREATE TRIGGER trg_delete_orphaned_favorite_details
AFTER DELETE ON favorites
FOR EACH ROW
BEGIN
    -- Delete all associated details from details_favorites
    -- where the favorite_id matches the ID of the deleted favorite record (OLD.id)
    DELETE FROM details_favorites
    WHERE favorite_id = OLD.id;
END$$

DELIMITER ;

 16. Actualizar campo updated_at en companies
"Como administrador, quiero un trigger que actualice el campo updated_at en companies."

🧠 Explicación: Como en productos, actualiza automáticamente la fecha de última modificación cada vez que se cambia algún dato.

ALTER TABLE companies
ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

DELIMITER $$

CREATE TRIGGER trg_companies_set_updated_at
BEFORE UPDATE ON companies
FOR EACH ROW
BEGIN
    -- Set the updated_at column to the current timestamp
    SET NEW.updated_at = NOW();
END$$

DELIMITER ;

 17. Impedir borrar ciudad si hay empresas activas
"Como desarrollador, deseo un trigger que impida borrar una ciudad si hay empresas activas en ella."

🧠 Explicación: Antes de hacer DELETE en citiesormunicipalities, el trigger revisa si hay empresas registradas en esa ciudad.


DELIMITER $$

CREATE TRIGGER trg_prevent_city_delete_if_companies_exist
BEFORE DELETE ON citiesormunicipalities
FOR EACH ROW
BEGIN
    DECLARE company_count INT;

    -- Contar el número de empresas asociadas a la ciudad que se intenta eliminar
    SELECT COUNT(*)
    INTO company_count
    FROM companies
    WHERE city_id = OLD.code; -- OLD.code se refiere al 'code' de la ciudad que se está intentando borrar

    -- Si hay empresas asociadas, impedir la eliminación y lanzar un error
    IF company_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se puede eliminar esta ciudad porque tiene empresas asociadas.';
    END IF;
END$$

DELIMITER ;

18. Registrar cambios de estado en encuestas
"Como auditor, quiero un trigger que registre cambios de estado de encuestas."

🧠 Explicación: Cada vez que se actualiza el campo status en polls, el trigger guarda la fecha, nuevo estado y usuario en un log.

DELIMITER $$

CREATE TRIGGER trg_log_poll_status_changes
AFTER UPDATE ON polls
FOR EACH ROW
BEGIN
    -- Solo registra si el campo 'isactive' ha cambiado
    IF OLD.isactive <> NEW.isactive THEN
        INSERT INTO bitacora (table_name, event_description)
        VALUES (
            'polls',
            CONCAT(
                'Cambio de estado en encuesta (ID: ', OLD.id, ', Nombre: ', OLD.name, '): ',
                'Estado anterior = ', IF(OLD.isactive, 'Activa', 'Inactiva'),
                ', Nuevo estado = ', IF(NEW.isactive, 'Activa', 'Inactiva'),
                ' por usuario = ', CURRENT_USER() -- Registra el usuario que realizó el cambio
            )
        );
    END IF;
END$$

DELIMITER ;




19. Sincronizar rates y quality_products
"Como supervisor, deseo un trigger que sincronice rates con quality_products al calificar."

🧠 Explicación: Inserta o actualiza la calidad del producto en quality_products cada vez que se inserta una nueva calificación.

ALTER TABLE companies
ADD COLUMN main_product_id INT(11),
ADD CONSTRAINT fk_companies_main_product
FOREIGN KEY (main_product_id) REFERENCES products(id); 

DELIMITER $$

CREATE TRIGGER trg_sync_rates_to_quality_products
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    DECLARE v_product_id INT;

   SELECT main_product_id
    INTO v_product_id
    FROM companies
    WHERE id = NEW.company_id;

   IF v_product_id IS NOT NULL THEN
       INSERT INTO quality_products (product_id, customer_id, poll_id, company_id, daterating, rating)
        VALUES (v_product_id, NEW.customer_id, NEW.poll_id, NEW.company_id, NEW.daterating, NEW.rating)
        ON DUPLICATE KEY UPDATE
             daterating = NEW.daterating,
            rating = NEW.rating;
    END IF;
END$$

DELIMITER ;


20. Eliminar productos sin relación a empresas
"Como operador, quiero un trigger que elimine automáticamente productos sin relación a empresas."

🧠 Explicación: Después de borrar la última relación entre un producto y una empresa (companyproducts), el trigger puede eliminar ese producto.

DELIMITER $$

CREATE TRIGGER trg_delete_orphaned_products
AFTER DELETE ON companyproducts
FOR EACH ROW
BEGIN
    DECLARE product_company_count INT;

    INTO product_company_count
    FROM companyproducts
    WHERE product_id = OLD.product_id;
          DELETE FROM products
        WHERE id = OLD.product_id;
    END IF;
END$$

DELIMITER ;














































































