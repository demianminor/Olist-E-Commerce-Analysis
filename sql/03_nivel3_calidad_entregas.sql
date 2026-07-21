-- ============================================================
-- NIVEL 3: ¿Qué está fallando?
-- Tabla: olist_orders_dataset
-- ============================================================

-- Distribución de order_status
SELECT order_status, COUNT(*) AS pedidos,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS porcentaje
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY pedidos DESC;

-- Tasa de entregas tardías (solo pedidos delivered)
SELECT
    COUNT(*) FILTER (WHERE order_delivered_customer_date > order_estimated_delivery_date) AS tardios,
    COUNT(*) AS total_delivered,
    ROUND(
        COUNT(*) FILTER (WHERE order_delivered_customer_date > order_estimated_delivery_date) * 100.0
        / COUNT(*), 2
    ) AS pct_tardios
FROM olist_orders_dataset
WHERE order_status = 'delivered';
-- Resultado: 8.11% de tardanza (7,826 de 96,478)

-- Tiempo promedio por etapa del proceso de entrega
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp)) / 86400)::numeric, 2) AS dias_aprobacion,
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_carrier_date - order_approved_at)) / 86400)::numeric, 2) AS dias_transportista,
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_delivered_carrier_date)) / 86400)::numeric, 2) AS dias_entrega,
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400)::numeric, 2) AS ciclo_total
FROM olist_orders_dataset
WHERE order_status = 'delivered';
-- Hallazgo clave: la etapa Transportista->Entrega concentra 74.3% del ciclo total (cuello de botella)
