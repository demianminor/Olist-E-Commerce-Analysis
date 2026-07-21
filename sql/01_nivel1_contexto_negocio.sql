-- ============================================================
-- NIVEL 1: Contexto base del negocio
-- Tablas: olist_orders_dataset, olist_order_payments_dataset, olist_customers_dataset
-- ============================================================

-- Volumen total de pedidos y periodo cubierto
SELECT
    COUNT(*) AS total_pedidos,
    MIN(order_purchase_timestamp) AS fecha_inicio,
    MAX(order_purchase_timestamp) AS fecha_fin
FROM olist_orders_dataset;
-- Resultado: 99,441 pedidos | Sep 2016 -> Oct 2018 (~25 meses)

-- Revenue total procesado
SELECT ROUND(SUM(payment_value)::numeric, 2) AS revenue_total
FROM olist_order_payments_dataset;
-- Resultado: R$16,008,872 (incluye producto + flete)

-- Clientes únicos reales (customer_id != customer_unique_id)
SELECT COUNT(DISTINCT customer_unique_id) AS clientes_unicos
FROM olist_customers_dataset;
-- Resultado: 96,096 -- Olist genera un customer_id nuevo por cada compra
