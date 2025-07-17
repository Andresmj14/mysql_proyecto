1. Obtener el promedio de calificación por producto
"Como analista, quiero obtener el promedio de calificación por producto."

🔍 Explicación para dummies: La persona encargada de revisar el rendimiento quiere saber qué tan bien calificado está cada producto. Con AVG(rating) agrupado por product_id, puede verlo de forma resumida.

SELECT  p.id, p.name AS producto, ROUND(AVG(qp.rating), 1) AS promedio_calificacion, COUNT(qp.rating) AS total_calificaciones
FROM  products p
LEFT JOIN  quality_products qp ON p.id = qp.product_id
GROUP BY  p.id, p.name
ORDER BY  promedio_calificacion DESC;

2. Contar cuántos productos ha calificado cada cliente
"Como gerente, desea contar cuántos productos ha calificado cada cliente."

🔍 Explicación: Aquí se quiere saber quiénes están activos opinando. Se usa COUNT(*) sobre rates, agrupando por customer_id.


SELECT  c.id, c.name AS cliente, COUNT(qp.product_id) AS productos_calificados
FROM  customers c
LEFT JOIN  quality_products qp ON c.id = qp.customer_id
GROUP BY  c.id, c.name
ORDER BY productos_calificados DESC;


3. Sumar el total de beneficios asignados por audiencia
"Como auditor, quiere sumar el total de beneficios asignados por audiencia."

🔍 Explicación: El auditor busca cuántos beneficios tiene cada tipo de usuario. Con COUNT(*) agrupado por audience_id en audiencebenefits, lo obtiene.

SELECT audience_id, COUNT(*) AS total_beneficios 
FROM audiencebenefits 
GROUP BY audience_id;

4. Calcular la media de productos por empresa
"Como administrador, desea conocer la media de productos por empresa."

🔍 Explicación: El administrador quiere saber si las empresas están ofreciendo pocos o muchos productos. Cuenta los productos por empresa y saca el promedio con AVG(cantidad).

SELECT AVG(productos.total) AS promedio_productos_por_empresa
FROM (SELECT COUNT(*) AS total FROM companyproducts GROUP BY company_id
) AS productos;

5. Contar el total de empresas por ciudad
"Como supervisor, quiere ver el total de empresas por ciudad."

🔍 Explicación: La idea es ver en qué ciudades hay más movimiento empresarial. Se usa COUNT(*) en companies, agrupando por city_id.

SELECT  c.code AS codigo_ciudad, c.name AS nombre_ciudad, COUNT(co.id) AS total_empresas
FROM  citiesormunicipalities c
LEFT JOIN  companies co ON c.code = co.city_id
GROUP BY  c.code, c.name
ORDER BY  total_empresas DESC;

6. Calcular el promedio de precios por unidad de medida
"Como técnico, desea obtener el promedio de precios de productos por unidad de medida."

🔍 Explicación: Se necesita saber si los precios son coherentes según el tipo de medida. Con AVG(price) agrupado por unit_id, se compara cuánto cuesta el litro, kilo, unidad, etc.

no me dio..


7. Contar cuántos clientes hay por ciudad
"Como gerente, quiere ver el número de clientes registrados por cada ciudad."

🔍 Explicación: Con COUNT(*) agrupado por city_id en la tabla customers, se obtiene la cantidad de clientes que hay en cada zona.

SELECT  c.code AS codigo_ciudad, c.name AS nombre_ciudad, COUNT(cl.id) AS total_clientes
FROM citiesormunicipalities c
LEFT JOIN customers cl ON c.code = cl.city_id
GROUP BY c.code, c.name
ORDER BY total_clientes DESC;


8. Calcular planes de membresía por periodo
"Como operador, desea contar cuántos planes de membresía existen por periodo."

🔍 Explicación: Sirve para ver qué tantos planes están vigentes cada mes o trimestre. Se agrupa por periodo (start_date, end_date) y se cuenta cuántos registros hay.

SELECT  p.name AS periodo, COUNT(mp.membership_id) AS total_planes
FROM periods p
LEFT JOIN membershipperiods mp ON p.id = mp.period_id
GROUP BY p.id, p.name
ORDER BY total_planes DESC;


9. Ver el promedio de calificaciones dadas por un cliente a sus favoritos
"Como cliente, quiere ver el promedio de calificaciones que ha otorgado a sus productos favoritos."

🔍 Explicación: El cliente quiere saber cómo ha calificado lo que más le gusta. Se hace un JOIN entre favoritos y calificaciones, y se saca AVG(rating).

SELECT  c.id AS cliente_id, c.name AS nombre_cliente, ROUND(AVG(qp.rating), 2) AS promedio_calificaciones_favoritos
FROM customers c
JOIN favorites f ON c.id = f.customer_id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN quality_products qp ON df.product_id = qp.product_id AND qp.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY promedio_calificaciones_favoritos DESC;


10. Consultar la fecha más reciente en que se calificó un producto
"Como auditor, desea obtener la fecha más reciente en la que se calificó un producto."

🔍 Explicación: Busca el MAX(created_at) agrupado por producto. Así sabe cuál fue la última vez que se evaluó cada uno.

SELECT  qp.product_id, p.name AS producto, MAX(qp.daterating) AS ultima_calificacion
FROM quality_products qp
JOIN products p ON qp.product_id = p.id
GROUP BY qp.product_id, p.name
ORDER BY ultima_calificacion DESC;

11. Obtener la desviación estándar de precios por categoría
"Como desarrollador, quiere conocer la variación de precios por categoría de producto."

🔍 Explicación: Usando STDDEV(price) en companyproducts agrupado por category_id, se puede ver si hay mucha diferencia de precios dentro de una categoría.

SELECT  c.id AS categoria_id, c.description AS nombre_categoria, ROUND(STDDEV(cp.price), 2) AS desviacion_estandar_precios, ROUND(AVG(cp.price), 2) AS precio_promedio, COUNT(DISTINCT cp.product_id) AS productos_analizados
FROM categories c
JOIN products p ON c.id = p.category_id
JOIN companyproducts cp ON p.id = cp.product_id
GROUP BY c.id, c.description
ORDER BY desviacion_estandar_precios DESC;

12. Contar cuántas veces un producto fue favorito
"Como técnico, desea contar cuántas veces un producto fue marcado como favorito."

🔍 Explicación: Con COUNT(*) en details_favorites, agrupado por product_id, se obtiene cuáles productos son los más populares entre los clientes.

SELECT p.id AS producto_id,p.name AS nombre_producto,COUNT(df.product_id) AS veces_favorito
FROM products p
LEFT JOIN details_favorites df ON p.id = df.product_id
GROUP BY p.id, p.name
ORDER BY veces_favorito DESC;

13. Calcular el porcentaje de productos evaluados
"Como director, quiere saber qué porcentaje de productos han sido calificados al menos una vez."

🔍 Explicación: Cuenta cuántos productos hay en total y cuántos han sido evaluados (rates). Luego calcula (evaluados / total) * 100.

SELECT (SELECT COUNT(*) FROM products) AS total_productos, (SELECT COUNT(DISTINCT product_id) FROM quality_products) AS productos_evaluados,
CONCAT(ROUND((SELECT COUNT(DISTINCT product_id) FROM quality_products) * 100.0 / 
(SELECT COUNT(*) FROM products),
2), '%') AS porcentaje_evaluados;


14. Ver el promedio de rating por encuesta
"Como analista, desea conocer el promedio de rating por encuesta."

🔍 Explicación: Agrupa por poll_id en rates, y calcula el AVG(rating) para ver cómo se comportó cada encuesta.

SELECT  p.id AS encuesta_id, p.name AS nombre_encuesta, ROUND(AVG(r.rating), 2) AS promedio_rating, COUNT(r.rating) AS total_respuestas
FROM polls p
LEFT JOIN rates r ON p.id = r.poll_id
GROUP BY p.id, p.name
ORDER BY promedio_rating DESC;

15. Calcular el promedio y total de beneficios por plan
"Como gestor, quiere obtener el promedio y el total de beneficios asignados a cada plan de membresía."

🔍 Explicación: Agrupa por membership_id en membershipbenefits, y usa COUNT(*) y AVG(beneficio) si aplica (si hay ponderación).

SELECT  m.name AS membresia, p.name AS periodo, COUNT(mb.benefit_id) AS total_beneficios, GROUP_CONCAT(b.description SEPARATOR ', ') AS lista_beneficios
FROM membershipperiods mp
JOIN memberships m ON mp.membership_id = m.id
JOIN periods p ON mp.period_id = p.id
LEFT JOIN membershipbenefits mb ON m.id = mb.membership_id AND p.id = mb.period_id
LEFT JOIN benefits b ON mb.benefit_id = b.id
GROUP BY m.name, p.name
ORDER BY m.name, total_beneficios DESC;

16. Obtener media y varianza de precios por empresa
"Como gerente, desea obtener la media y la varianza del precio de productos por empresa."

🔍 Explicación: Se agrupa por company_id y se usa AVG(price) y VARIANCE(price) para saber qué tan consistentes son los precios por empresa.

SELECT  company_id, AVG(price) AS media_precios, VARIANCE(price) AS varianza
FROM companyproducts
GROUP BY company_id
ORDER BY varianza DESC;


17. Ver total de productos disponibles en la ciudad del cliente
"Como cliente, quiere ver cuántos productos están disponibles en su ciudad."

🔍 Explicación: Hace un JOIN entre companies, companyproducts y citiesormunicipalities, filtrando por la ciudad del cliente. Luego se cuenta.

no pude..

18. Contar productos únicos por tipo de empresa
"Como administrador, desea contar los productos únicos por tipo de empresa."

🔍 Explicación: Agrupa por company_type_id y cuenta cuántos productos diferentes tiene cada tipo de empresa.

SELECT ti.description AS tipo_empresa,cat.description AS categoria_producto,COUNT(DISTINCT cp.product_id) AS productos_unicos
FROM typesofidentifications ti
JOIN companies c ON ti.id = c.type_id
JOIN companyproducts cp ON c.id = cp.company_id
JOIN products p ON cp.product_id = p.id
JOIN categories cat ON p.category_id = cat.id
GROUP BY ti.description, cat.description
ORDER BY tipo_empresa, productos_unicos DESC;

19. Ver total de clientes sin correo electrónico registrado
"Como operador, quiere saber cuántos clientes no han registrado su correo."

🔍 Explicación: Filtra customers WHERE email IS NULL y hace un COUNT(*). Esto ayuda a mejorar la base de datos para campañas.

SELECT COUNT(*) AS total_clientes_sin_email
FROM customers
WHERE email IS NULL;

20. Empresa con más productos calificados
"Como especialista, desea obtener la empresa con el mayor número de productos calificados."

🔍 Explicación: Hace un JOIN entre companies, companyproducts, y rates, agrupa por empresa y usa COUNT(DISTINCT product_id), ordenando en orden descendente y tomando solo el primero.

SELECT c.name AS nombre_empresa, COUNT(DISTINCT qp.product_id) AS total_productos_calificados
FROM companies AS c
JOIN quality_products AS qp ON c.id = qp.company_id
GROUP BY c.name
ORDER BY total_productos_calificados DESC
LIMIT 1;























