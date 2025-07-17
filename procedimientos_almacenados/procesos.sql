4. Procedimientos Almacenados

1. Registrar una nueva calificación y actualizar el promedio
"Como desarrollador, quiero un procedimiento que registre una calificación y actualice el promedio del producto."

🧠 Explicación: Este procedimiento recibe product_id, customer_id y rating, inserta la nueva fila en rates, y recalcula automáticamente el promedio en la tabla products (campo average_rating).

DELIMITER $$

CREATE PROCEDURE RegistrarCalificacionYActualizarPromedio(
    IN p_product_id INT,
    IN p_customer_id INT,
    IN p_company_id VARCHAR(20),
    IN p_poll_id INT,
    IN p_rating DOUBLE(10,2)
)
BEGIN
    INSERT INTO rates (product_id, customer_id, company_id, poll_id, daterating, rating)
    VALUES (p_product_id, p_customer_id, p_company_id, p_poll_id, NOW(), p_rating);

    
    UPDATE products
    SET average_rating = (
        SELECT AVG(r.rating)
        FROM rates AS r
        WHERE r.product_id = p_product_id
    )
    WHERE id = p_product_id;
END$$

DELIMITER ;

2. Insertar empresa y asociar productos por defecto
"Como administrador, deseo un procedimiento para insertar una empresa y asociar productos por defecto."

🧠 Explicación: Este procedimiento inserta una empresa en companies, y luego vincula automáticamente productos predeterminados en companyproducts.

DELIMITER $$

CREATE PROCEDURE InsertarEmpresaYAsociarProductosDefecto(
    IN p_id VARCHAR(20),
    IN p_type_id INT,
    IN p_name VARCHAR(80),
    IN p_category_id INT,
    IN p_city_id VARCHAR(6),
    IN p_audience_id INT,
    IN p_cellphone VARCHAR(15),
    IN p_email VARCHAR(80)
)
BEGIN
   
    DECLARE default_product_price DOUBLE(10,2);
    DECLARE default_unitmeasure_id INT;

    
    INSERT INTO companies (id, type_id, name, category_id, city_id, audience_id, cellphone, email)
    VALUES (p_id, p_type_id, p_name, p_category_id, p_city_id, p_audience_id, p_cellphone, p_email);

    
    SET default_product_price = 10.00; 
    SET default_unitmeasure_id = 1;   

    INSERT INTO companyproducts (company_id, product_id, price, unitmeasure_id) VALUES
    (p_id, 1, default_product_price, default_unitmeasure_id),
    (p_id, 2, default_product_price, default_unitmeasure_id),
    (p_id, 3, default_product_price, default_unitmeasure_id);

END$$

DELIMITER ;

CALL InsertarEmpresaYAsociarProductosDefecto(
    'EMP005', 1, 'Mi Nueva Empresa S.A.S.', 1, 'C00001',1, '3001234567', 'contacto@minuevaempresa.com'
);

3. Añadir producto favorito validando duplicados
"Como cliente, quiero un procedimiento que añada un producto favorito y verifique duplicados."

🧠 Explicación: Verifica si el producto ya está en favoritos (details_favorites). Si no lo está, lo inserta. Evita duplicaciones silenciosamente.

DELIMITER $$

CREATE PROCEDURE AnadirProductoFavorito(
    IN p_customer_id INT,
    IN p_company_id VARCHAR(20),
    IN p_product_id INT
)
BEGIN
    DECLARE v_favorite_id INT;

    SELECT id INTO v_favorite_id
    FROM favorites
    WHERE customer_id = p_customer_id AND company_id = p_company_id;

    IF v_favorite_id IS NULL THEN
        INSERT INTO favorites (customer_id, company_id)
        VALUES (p_customer_id, p_company_id);

       SET v_favorite_id = LAST_INSERT_ID();
    END IF;

   IF NOT EXISTS (
        SELECT 1
        FROM details_favorites
        WHERE favorite_id = v_favorite_id AND product_id = p_product_id
    ) THEN
    
        INSERT INTO details_favorites (favorite_id, product_id)
        VALUES (v_favorite_id, p_product_id);
    END IF;

END$$

DELIMITER ;

CALL AnadirProductoFavorito(
    101,        
    'EMP001',  
    500      
);

4. Generar resumen mensual de calificaciones por empresa
"Como gestor, deseo un procedimiento que genere un resumen mensual de calificaciones por empresa."

🧠 Explicación: Hace una consulta agregada con AVG(rating) por empresa, y guarda los resultados en una tabla de resumen tipo resumen_calificaciones.


DELIMITER $$

CREATE PROCEDURE GenerarResumenMensualCalificaciones(
    IN p_mes INT,
    IN p_anio INT
)
BEGIN
     DELETE FROM resumen_calificaciones
    WHERE mes = p_mes AND año = p_anio;

 
    INSERT INTO resumen_calificaciones (empresa_id, mes, año, promedio_calificacion, total_calificaciones, fecha_generacion)
    SELECT
        qp.company_id AS empresa_id,
        MONTH(qp.daterating) AS mes,
        YEAR(qp.daterating) AS año,
        AVG(qp.rating) AS promedio_calificacion,
        COUNT(qp.rating) AS total_calificaciones,
        NOW() AS fecha_generacion
    FROM
        quality_products AS qp
    WHERE
        MONTH(qp.daterating) = p_mes AND YEAR(qp.daterating) = p_anio
    GROUP BY
        qp.company_id, MONTH(qp.daterating), YEAR(qp.daterating);

END$$

DELIMITER ;

CALL GenerarResumenMensualCalificaciones(7, 2024);

SELECT * FROM resumen_calificaciones;

5. Calcular beneficios activos por membresía
"Como supervisor, quiero un procedimiento que calcule beneficios activos por membresía."

🧠 Explicación: Consulta membershipbenefits junto con membershipperiods, y devuelve una lista de beneficios vigentes según la fecha actual.

no me salio..


6. Eliminar productos huérfanos
"Como técnico, deseo un procedimiento que elimine productos sin calificación ni empresa asociada."

🧠 Explicación: Elimina productos de la tabla products que no tienen relación ni en rates ni en companyproducts.

DELIMITER $$

CREATE PROCEDURE EliminarProductosHuerfanos()
BEGIN
    DELETE FROM products
    WHERE id NOT IN (SELECT DISTINCT product_id FROM rates)
    AND id NOT IN (SELECT DISTINCT product_id FROM companyproducts);
    SELECT ROW_COUNT() AS productos_eliminados;
END$$

DELIMITER ;
CALL EliminarProductosHuerfanos();

7. Actualizar precios de productos por categoría
"Como operador, quiero un procedimiento que actualice precios de productos por categoría."

🧠 Explicación: Recibe un categoria_id y un factor (por ejemplo 1.05), y multiplica todos los precios por ese factor en la tabla companyproducts.

DELIMITER $$

CREATE PROCEDURE ActualizarPreciosPorCategoria(
    IN p_category_id INT,
    IN p_factor DOUBLE(10,2)
)
BEGIN
    UPDATE companyproducts cp
    JOIN products p ON cp.product_id = p.id
    SET cp.price = cp.price * p_factor
    WHERE p.category_id = p_category_id;
    SELECT ROW_COUNT() AS productos_actualizados;

END$$

DELIMITER ;
CALL ActualizarPreciosPorCategoria(1, 1.10);

CALL ActualizarPreciosPorCategoria(2, 0.95);



8. Validar inconsistencia entre rates y quality_products
"Como auditor, deseo un procedimiento que liste inconsistencias entre rates y quality_products."

🧠 Explicación: Busca calificaciones (rates) que no tengan entrada correspondiente en quality_products. Inserta el error en una tabla errores_log.

DELIMITER $$

CREATE PROCEDURE ReporteClientesPorMembresiaActiva(
    IN p_fecha_consulta DATE
)
BEGIN
    SELECT
        c.id AS customer_id,
        c.name AS nombre_cliente,
        c.email AS email_cliente,
        c.cellphone AS telefono_cliente,
        m.name AS nombre_membresia,
        cm.start_date AS fecha_inicio_membresia,
        cm.end_date AS fecha_fin_membresia
    FROM customers AS c
    JOIN customer_memberships AS cm ON c.id = cm.customer_id
    JOIN memberships AS m ON cm.membership_id = m.id
    WHERE p_fecha_consulta BETWEEN cm.start_date AND cm.end_date AND cm.isactive = TRUE;

END$$

DELIMITER ;


CALL ReporteClientesPorMembresiaActiva('2024-07-15');

CALL ReporteClientesPorMembresiaActiva(CURDATE());


9. Asignar beneficios a nuevas audiencias
"Como desarrollador, quiero un procedimiento que asigne beneficios a nuevas audiencias."

🧠 Explicación: Recibe un benefit_id y audience_id, verifica si ya existe el registro, y si no, lo inserta en audiencebenefits.

DELIMITER $$

CREATE PROCEDURE AsignarBeneficioANuevaAudiencia(
    IN p_audience_id INT,
    IN p_benefit_id INT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM audiencebenefits
        WHERE audience_id = p_audience_id AND benefit_id = p_benefit_id
    ) THEN
        INSERT INTO audiencebenefits (audience_id, benefit_id)
        VALUES (p_audience_id, p_benefit_id);

        SELECT 'Beneficio asignado exitosamente.' AS mensaje, 1 AS filas_afectadas;
    ELSE
        SELECT 'La asignación de este beneficio a esta audiencia ya existe.' AS mensaje, 0 AS filas_afectadas;
    END IF;

END$$

DELIMITER ;

-
CALL AsignarBeneficioANuevaAudiencia(1, 10);

CALL AsignarBeneficioANuevaAudiencia(1, 10);

CALL AsignarBeneficioANuevaAudiencia(1, 11);

10. Activar planes de membresía vencidos con pago confirmado
"Como administrador, deseo un procedimiento que active planes de membresía vencidos si el pago fue confirmado."

🧠 Explicación: Actualiza el campo status a 'ACTIVA' en membershipperiods donde la fecha haya vencido pero el campo pago_confirmado sea TRUE.

ALTER TABLE membershipperiods
ADD COLUMN effective_date DATE, 
ADD COLUMN expiration_date DATE, 
ADD COLUMN payment_confirmed BOOLEAN DEFAULT FALSE; 

DELIMITER $$

CREATE PROCEDURE ActivarPlanesMembresiaVencidosConPago()
BEGIN
    UPDATE membershipperiods
    SET
        isactive = TRUE, expiration_date = DATE_ADD(expiration_date, INTERVAL 1 YEAR) 
        WHERE expiration_date < CURDATE() 
        AND payment_confirmed = TRUE 
        AND isactive = FALSE;

    SELECT ROW_COUNT() AS planes_actualizados;

END$$

DELIMITER ;
CALL ActivarPlanesMembresiaVencidosConPago();

11. Listar productos favoritos del cliente con su calificación
"Como cliente, deseo un procedimiento que me devuelva todos mis productos favoritos con su promedio de rating."

🧠 Explicación: Consulta todos los productos favoritos del cliente y muestra el promedio de calificación de cada uno, uniendo favorites, rates y products.

DELIMITER $$

CREATE PROCEDURE ListarProductosFavoritosConCalificacion(
    IN p_customer_id INT
)
BEGIN
    SELECT
        p.name AS nombre_producto,
        p.detail AS detalle_producto,
        p.price AS precio_producto,
        c.name AS nombre_empresa,
        AVG(qp.rating) AS promedio_calificacion
    FROM
        customers AS cust
    JOIN
        favorites AS f ON cust.id = f.customer_id
    JOIN
        details_favorites AS df ON f.id = df.favorite_id
    JOIN
        products AS p ON df.product_id = p.id
    LEFT JOIN quality_products AS qp ON p.id = qp.product_id AND f.company_id = qp.company_id 
    LEFT JOIN companies AS c ON f.company_id = c.id
    WHERE cust.id = p_customer_id
    GROUP BY p.id, p.name, p.detail, p.price, c.name;

END$$

DELIMITER ;

CALL ListarProductosFavoritosConCalificacion(1);

12. Registrar encuesta y sus preguntas asociadas
"Como gestor, quiero un procedimiento que registre una encuesta y sus preguntas asociadas."

🧠 Explicación: Inserta la encuesta principal en polls y luego cada una de sus preguntas en otra tabla relacionada como poll_questions.

CREATE TABLE IF NOT EXISTS poll_questions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    poll_id INT NOT NULL,
    question_text TEXT NOT NULL,
    question_order INT, -- Para el orden de las preguntas
    FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE CASCADE
);

DELIMITER $$

CREATE PROCEDURE RegistrarEncuestaYPreguntas(
    IN p_nombre_encuesta VARCHAR(80),
    IN p_descripcion_encuesta TEXT,
    IN p_esta_activa BOOLEAN,
    IN p_id_categoria_encuesta INT,
    IN p_preguntas_json JSON -- Aquí va un JSON con tus preguntas, ¡así de fácil!
)
BEGIN
    DECLARE v_id_encuesta_nueva INT;
    DECLARE i INT DEFAULT 0;
    DECLARE v_texto_pregunta TEXT;
    DECLARE v_orden_pregunta INT;
    DECLARE v_total_preguntas INT;

    INSERT INTO polls (name, description, isactive, categorypoll_id)
    VALUES (p_nombre_encuesta, p_descripcion_encuesta, p_esta_activa, p_id_categoria_encuesta);

  SET v_id_encuesta_nueva = LAST_INSERT_ID();

    SET v_total_preguntas = JSON_LENGTH(p_preguntas_json);

    WHILE i < v_total_preguntas DO
       SET v_texto_pregunta = JSON_UNQUOTE(JSON_EXTRACT(p_preguntas_json, CONCAT('$[', i, '].texto')));
        SET v_orden_pregunta = JSON_UNQUOTE(JSON_EXTRACT(p_preguntas_json, CONCAT('$[', i, '].orden')));

        INSERT INTO poll_questions (poll_id, question_text, question_order)
        VALUES (v_id_encuesta_nueva, v_texto_pregunta, v_orden_pregunta);

        SET i = i + 1;
    END WHILE;

    SELECT CONCAT('¡Encuesta "', p_nombre_encuesta, '" y sus preguntas se han registrado con éxito! ID de encuesta: ', v_id_encuesta_nueva) AS MensajeConfirmacion;

END$$

DELIMITER ;

CALL RegistrarEncuestaYPreguntas(
    'Feedback del Producto X',                    
    'Queremos saber tu opinión sobre nuestro nuevo Producto X.',
    TRUE,                                         
    1,                                            
    '[
        {"texto": "¿Qué tal el Producto X en general?", "orden": 1},
        {"texto": "¿Lo recomendarías a tus amigos?", "orden": 2},
        {"texto": "¿Qué mejorarías del Producto X?", "orden": 3}
    ]'                                             
);

13. Eliminar favoritos antiguos sin calificaciones
"Como técnico, deseo un procedimiento que borre favoritos antiguos no calificados en más de un año."

🧠 Explicación: Filtra productos favoritos que no tienen calificaciones recientes y fueron añadidos hace más de 12 meses, y los elimina de details_favorites.

DELIMITER $$

CREATE PROCEDURE EliminarFavoritosAntiguosSinCalificaciones()
BEGIN
    DECLARE fecha_limite_antiguedad DATE;
    DECLARE fecha_limite_calificacion DATE;

    
    SET fecha_limite_antiguedad = DATE_SUB(CURDATE(), INTERVAL 1 YEAR);
    SET fecha_limite_calificacion = DATE_SUB(CURDATE(), INTERVAL 1 YEAR);

    
    DELETE df
    FROM details_favorites df
    JOIN favorites f ON df.favorite_id = f.id
    LEFT JOIN quality_products qp ON df.product_id = qp.product_id AND f.company_id = qp.company_id
    WHERE f.creation_date < fecha_limite_antiguedad
        AND
     
        (
            qp.product_id IS NULL OR 
            NOT EXISTS (
                SELECT 1
                FROM quality_products qp_inner
                WHERE qp_inner.product_id = df.product_id
                  AND qp_inner.company_id = f.company_id  AND qp_inner.daterating >= fecha_limite_calificacion 
            )
        );

    
    SELECT ROW_COUNT() AS favoritos_eliminados;

END$$

DELIMITER ;

ALTER TABLE favorites
ADD COLUMN creation_date DATETIME DEFAULT CURRENT_TIMESTAMP;

CALL EliminarFavoritosAntiguosSinCalificaciones();

14. Asociar beneficios automáticamente por audiencia
"Como operador, quiero un procedimiento que asocie automáticamente beneficios por audiencia."

🧠 Explicación: Inserta en audiencebenefits todos los beneficios que apliquen según una lógica predeterminada (por ejemplo, por tipo de usuario).

DELIMITER $$

CREATE PROCEDURE AsociarBeneficiosAutomaticamentePorAudiencia(
    IN p_audience_id INT
)
BEGIN
    INSERT INTO audiencebenefits (audience_id, benefit_id)
    SELECT
        p_audience_id AS audience_id,
        b.id AS benefit_id
    FROM
        benefits AS b
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM audiencebenefits ab
            WHERE ab.audience_id = p_audience_id AND ab.benefit_id = b.id
        );

    SELECT ROW_COUNT() AS beneficios_asociados;

END$$

DELIMITER ;

CALL AsociarBeneficiosAutomaticamentePorAudiencia(1);

CALL AsociarBeneficiosAutomaticamentePorAudiencia(2);

15. Historial de cambios de precio
"Como administrador, deseo un procedimiento para generar un historial de cambios de precio."

🧠 Explicación: Cada vez que se cambia un precio, el procedimiento compara el anterior con el nuevo y guarda un registro en una tabla historial_precios.

no me dio..

16. Registrar encuesta activa automáticamente
"Como desarrollador, quiero un procedimiento que registre automáticamente una nueva encuesta activa."

🧠 Explicación: Inserta una encuesta en polls con el campo status = 'activa' y una fecha de inicio en NOW().

DELIMITER $$

CREATE PROCEDURE registrar_encuesta_activa(
    IN p_name VARCHAR(80),
    IN p_description TEXT,
    IN p_categorypoll_id INT
)
BEGIN
    INSERT INTO polls (name, description, isactive, categorypoll_id)
    VALUES (p_name, p_description, TRUE, p_categorypoll_id);
END$$

DELIMITER ;


ALTER TABLE polls ADD COLUMN creation_date DATETIME DEFAULT CURRENT_TIMESTAMP;

CALL registrar_encuesta_activa(
    'Encuesta de Satisfacción del Cliente Q3', 
    'Evalúa la satisfacción general de los clientes con nuestros servicios durante el tercer trimestre.',
    1 
);

17. Actualizar unidad de medida de productos sin afectar ventas
"Como técnico, deseo un procedimiento que actualice la unidad de medida de productos sin afectar si hay ventas."

🧠 Explicación: Verifica si el producto no ha sido vendido, y si es así, permite actualizar su unit_id.

DELIMITER $$

CREATE PROCEDURE actualizar_unidad_medida_producto(
    IN p_company_id VARCHAR(20),
    IN p_product_id INT,
    IN p_new_unitmeasure_id INT
)
BEGIN
    DECLARE v_rating_count INT;
    DECLARE v_message VARCHAR(255);

     SELECT COUNT(*)
    INTO v_rating_count
    FROM quality_products
    WHERE product_id = p_product_id AND company_id = p_company_id;

    IF v_rating_count = 0 THEN
        UPDATE companyproducts
        SET unitmeasure_id = p_new_unitmeasure_id
        WHERE company_id = p_company_id AND product_id = p_product_id;

        IF ROW_COUNT() > 0 THEN
            SET v_message = '✅ ¡Éxito! La unidad de medida se actualizó correctamente.';
        ELSE
            SET v_message = '⚠️ Advertencia: El producto no fue encontrado para la empresa especificada. No se realizó la actualización.';
        END IF;
    ELSE
       SET v_message = '❌ Error: No se puede actualizar. El producto ya tiene calificaciones (ventas) asociadas.';
    END IF;
 
    SELECT v_message AS 'Resultado';

END$$

DELIMITER ;

CALL actualizar_unidad_medida_producto('NIT900123456', 101, 5);


18. Recalcular promedios de calidad semanalmente
"Como supervisor, quiero un procedimiento que recalcule todos los promedios de calidad cada semana."

🧠 Explicación: Hace un AVG(rating) agrupado por producto y lo actualiza en products.

DELIMITER $$

CREATE PROCEDURE recalcular_promedios_calidad_productos()
BEGIN

    UPDATE products p
    JOIN (
        SELECT 
            product_id, 
            AVG(rating) AS avg_rating
        FROM quality_products
        GROUP BY product_id
    ) AS ratings_summary ON p.id = ratings_summary.product_id
    SET p.average_rating = ratings_summary.avg_rating;

END$$

DELIMITER ;

CALL recalcular_promedios_calidad_productos();


SET GLOBAL event_scheduler = ON;

CREATE EVENT evento_recalculo_semanal
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
  CALL recalcular_promedios_calidad_productos();


19. Validar claves foráneas entre calificaciones y encuestas
"Como auditor, deseo un procedimiento que valide claves foráneas cruzadas entre calificaciones y encuestas."

🧠 Explicación: Busca registros en rates con poll_id que no existen en polls, y los reporta.

DELIMITER //

CREATE PROCEDURE ValidateRatesPollsForeignKey()
BEGIN
    SELECT
        r.customer_id,
        r.company_id,
        r.poll_id AS invalid_poll_id,
        'Poll ID not found in polls table' AS validation_error
    FROM
        rates r
    LEFT JOIN
        polls p ON r.poll_id = p.id
    WHERE
        p.id IS NULL;
END //

DELIMITER ;

CALL ValidateRatesPollsForeignKey();

20. Generar el top 10 de productos más calificados por ciudad
"Como gerente, quiero un procedimiento que genere el top 10 de productos más calificados por ciudad."

🧠 Explicación: Agrupa las calificaciones por ciudad (a través de la empresa que lo vende) y selecciona los 10 productos con más evaluaciones.

DELIMITER //

CREATE PROCEDURE GetTop10RatedProductsByCity()
BEGIN
    SELECT
        c.name AS city_name,
        p.name AS product_name,
        COUNT(qp.product_id) AS total_ratings
    FROM
        quality_products qp
    JOIN
        products p ON qp.product_id = p.id
    JOIN
        companies comp ON qp.company_id = comp.id
    JOIN
        citiesormunicipalities c ON comp.city_id = c.code
    GROUP BY
        c.name, p.name
    ORDER BY
        c.name, total_ratings DESC;

END //

DELIMITER ;

CALL GetTop10RatedProductsByCity();












