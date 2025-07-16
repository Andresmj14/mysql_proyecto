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

