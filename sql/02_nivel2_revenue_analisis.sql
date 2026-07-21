-- ============================================================
-- NIVEL 2: ¿Dónde está el dinero?
-- Tablas: order_items -> products -> category_translation, sellers
-- ============================================================

-- Revenue por categoría de producto
SELECT
    tr.product_category_name_english AS categoria,
    ROUND(SUM(oi.price)::numeric, 2) AS revenue,
    COUNT(*) AS pedidos,
    ROUND(AVG(oi.price)::numeric, 2) AS ticket_promedio
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
JOIN product_category_name_translation tr ON p.product_category_name = tr.product_category_name
GROUP BY tr.product_category_name_english
ORDER BY revenue DESC;

-- Métodos de pago
SELECT
    payment_type,
    COUNT(*) AS transacciones,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY revenue DESC;
-- credit_card domina con 73% de las transacciones

-- Total de vendedores únicos
SELECT COUNT(DISTINCT seller_id) AS total_vendedores
FROM olist_sellers_dataset;
-- Resultado: 3,095
