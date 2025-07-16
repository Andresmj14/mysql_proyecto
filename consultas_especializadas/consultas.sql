--Consultas SQL Especializadas
--1. Como analista, quiero listar todos los productos con su empresa asociada y el precio más bajo por ciudad.

    SELECT 
    p.id AS producto_id,
    p.name AS nombre_producto,
    c.id AS empresa_id,
    c.name AS nombre_empresa,
    cm.name AS ciudad,
    cp.price AS precio,
    'Más bajo' AS tipo_precio
FROM 
    companyproducts cp
JOIN 
    products p ON cp.product_id = p.id
JOIN 
    companies c ON cp.company_id = c.id
JOIN 
    citiesormunicipalities cm ON c.city_id = cm.code
WHERE 
    cp.price = (
        SELECT MIN(cp2.price)
        FROM companyproducts cp2
        JOIN companies c2 ON cp2.company_id = c2.id
        WHERE cp2.product_id = p.id AND c2.city_id = c.city_id
    )
ORDER BY 
    p.name, cm.name;

-- 2.Como administrador, deseo obtener el top 5 de clientes que más productos han calificado en los últimos 6 meses.

SELECT 
    c.id AS cliente_id,
    c.name AS nombre_cliente,
    c.email AS correo_electronico,
    COUNT(qp.product_id) AS total_calificaciones,
    AVG(qp.rating) AS promedio_calificacion
FROM 
    customers c
JOIN 
    quality_products qp ON c.id = qp.customer_id
WHERE 
    qp.daterating >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
GROUP BY 
    c.id, c.name, c.email
ORDER BY 
    total_calificaciones DESC
LIMIT 5;


-- 3. Como gerente de ventas, quiero ver la distribución de productos por categoría y unidad de medida

SELECT cat.description AS categoria, 
um.description AS unidad_medida,
COUNT(p.id) AS cantidad_productos,
round(AVG(cp.price), 2) AS precio_promedio,
MIN(cp.price) AS precio_minimo,
MAX(cp.price) AS precio_maximo
FROM products p 
JOIN categories cat ON p.category_id = cat.id 
JOIN companyproducts cp ON p.id = cp.product_id 
JOIN unitofmeasure um ON cp.unitmeasure_id = um.id 
GROUP BY cat.description, um.description
ORDER BY cat.description, cantidad_productos DESC;

-- 4.Como cliente, quiero saber qué productos tienen calificaciones superiores al promedio general.
SELECT p.name AS 'Productos mejor calificados'
FROM products p
JOIN quality_products q ON p.id = q.product_id
GROUP BY p.name
HAVING AVG(q.rating) > (SELECT AVG(rating) FROM quality_products)
ORDER BY AVG(q.rating) DESC LIMIT 6;

--6. Como operador, deseo obtener los productos que han sido añadidos como favoritos por más de 10 clientes distintos.

 SELECT p.name as productos, df.favorite_id as favorito, fv.customer_id as cliente
 FROM products p 
 JOIN details_favorites df ON p.id = df.product_id
 JOIN favorites fv ON df.favorite_id = fv.id
 ORDER BY df.favorite_id, p.name DESC LIMIT 10;

SUBCONSULTAS

--1. Como gerente, quiero ver los productos cuyo precio esté por encima del promedio de su categoría.

SELECT 
    p.name AS 'Producto Premium',
    cat.description AS 'Categoría',
    CONCAT('$', FORMAT(cp.price, 0)) AS 'Precio',
    CONCAT('$', FORMAT(
        (SELECT AVG(cp2.price) 
         FROM companyproducts cp2 
         JOIN products p2 ON cp2.product_id = p2.id 
         WHERE p2.category_id = p.category_id), 0
    )) AS 'Promedio Categoría'
FROM 
    products p
JOIN 
    companyproducts cp ON p.id = cp.product_id
JOIN 
    categories cat ON p.category_id = cat.id
WHERE 
    cp.price > (
        SELECT AVG(cp2.price) 
        FROM companyproducts cp2 
        JOIN products p2 ON cp2.product_id = p2.id 
        WHERE p2.category_id = p.category_id
    )
ORDER BY 
    p.name;

-- 2. Como administrador, deseo listar las empresas que tienen más productos que la media de empresas.


