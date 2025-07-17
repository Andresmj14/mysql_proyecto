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
SELECT   c.id, c.name, COUNT(cp.product_id) AS product_count
FROM  companies c
JOIN  companyproducts cp ON c.id = cp.company_id
GROUP BY  c.id, c.name
ORDER BY  product_count DESC
LIMIT 10; 

--3. Como cliente, quiero ver mis productos favoritos que han sido calificados por otros clientes.
no pude...

--4. Como supervisor, deseo obtener los productos con el mayor número de veces añadidos como favoritos.

SELECT  p.id, p.name AS producto, favoritos.contador AS veces_favorito
FROM  products p
JOIN  (SELECT product_id, COUNT(*) AS contador FROM details_favorites GROUP BY product_id) AS favoritos ON p.id = favoritos.product_id
ORDER BY  favoritos.contador DESC LIMIT 10;

--5. Como técnico, quiero listar los clientes cuyo correo no aparece en la tabla rates ni en quality_products.
SELECT  c.id,.name AS nombre_cliente, .email
FROM  customers c
WHERE  c.id NOT IN (SELECT DISTINCT customer_id FROM rates  UNION  SELECT DISTINCT customer_id FROM quality_products)
ORDER BY  c.name;

--6.Como gestor de calidad, quiero obtener los productos con una calificación inferior al mínimo de su categoría.

no pude..

--7. Como desarrollador, deseo listar las ciudades que no tienen clientes registrados.

SELECT  c.code, c.name AS ciudad, sr.name AS region, co.name AS pais
FROM  citiesormunicipalities c
JOIN  stateregions sr ON c.statereg_id = sr.code
JOIN  countries co ON sr.country_id = co.isocode
WHERE c.code NOT IN (
        SELECT DISTINCT city_id 
        FROM customers 
        WHERE city_id IS NOT NULL
        );

--8. Como administrador, quiero ver los productos que no han sido evaluados en ninguna encuesta.

SELECT  p.id, p.name AS producto, c.description AS categoria
FROM  products p
JOIN  categories c ON p.category_id = c.id
WHERE p.id NOT IN (
        SELECT DISTINCT product_id 
        FROM quality_products
        )
ORDER BY  p.name;

--9. Como auditor, quiero listar los beneficios que no están asignados a ninguna audiencia.

SELECT  b.id, b.description AS beneficio
FROM  benefits b
WHERE  NOT EXISTS (
    SELECT 1 
    FROM audiencebenefits ab 
    WHERE ab.benefit_id = b.id
);

--11. Como director, deseo consultar los productos vendidos en empresas cuya ciudad tenga menos de tres empresas registradas.

SELECT p.name AS producto, c.name AS empresa, ci.name AS ciudad
FROM products p
JOIN companyproducts cp ON p.id = cp.product_id
JOIN companies c ON cp.company_id = c.id
JOIN citiesormunicipalities ci ON c.city_id = ci.code
WHERE ci.code IN (
    SELECT city_id
    FROM companies
    GROUP BY city_id
    HAVING COUNT(*) < 3
)
ORDER BY ci.name, p.name;

