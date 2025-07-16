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
