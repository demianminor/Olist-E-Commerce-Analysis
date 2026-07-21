-- ============================================================
-- PÁGINA 4: Vendor Scorecard - Índice de eficiencia por estado
-- Tablas: sellers, order_items
-- ============================================================

-- Índice de eficiencia = (% revenue del estado) / (% vendedores del estado)
-- Índice > 1: el estado vende más de lo que "le toca" según su cantidad de vendedores
SELECT
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS vendedores_estado,
    ROUND(SUM(oi.price)::numeric, 2) AS revenue_estado,
    ROUND(
        COUNT(DISTINCT s.seller_id)::numeric
        / (SELECT COUNT(DISTINCT seller_id) FROM olist_sellers_dataset) * 100
    , 2) AS pct_vendedores,
    ROUND(
        SUM(oi.price)::numeric
        / (SELECT SUM(price) FROM olist_order_items_dataset) * 100
    , 2) AS pct_revenue,
    ROUND(
        (SUM(oi.price)::numeric / (SELECT SUM(price) FROM olist_order_items_dataset))
        /
        (COUNT(DISTINCT s.seller_id)::numeric / (SELECT COUNT(DISTINCT seller_id) FROM olist_sellers_dataset))
    , 2) AS indice_eficiencia
FROM olist_sellers_dataset s
LEFT JOIN olist_order_items_dataset oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_state
HAVING COUNT(DISTINCT s.seller_id) >= 20  -- filtra estados con muestra insuficiente
ORDER BY indice_eficiencia DESC;
