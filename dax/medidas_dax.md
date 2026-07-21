# Medidas DAX — Modelo Olist

Librería de referencia. Cada medida vive dentro de su tabla fuente. Toda medida se valida contra una query SQL equivalente antes de darse por final (ver carpeta `/sql`).

## Medidas base

```dax
Revenue Total = SUM(olist_order_items_dataset[price])

Revenue Total con flete = [Revenue Total] + SUM(olist_order_items_dataset[freight_value])

Total Pedidos = COUNT(olist_orders_dataset[order_id])

Numero de Clientes = DISTINCTCOUNT(olist_customers_dataset[customer_unique_id])
-- usa customer_unique_id, NO customer_id (Olist genera un ID nuevo por compra)

Ticket Promedio = DIVIDE([Revenue Total], [Total Pedidos])

Ticket Mediana = MEDIAN(olist_order_items_dataset[price])
```

## Medidas de liderazgo por categoría/estado

```dax
Lider Revenue =
CALCULATE(MAX(product_category_name_translation[product_category_name_english]),
    TOPN(1, VALUES(product_category_name_translation[product_category_name_english]),
    [Revenue Total con flete], DESC))

Estado Lider Revenue =
CALCULATE(MAX(olist_customers_dataset[customer_state]),
    TOPN(1, VALUES(olist_customers_dataset[customer_state]),
    [Revenue Total con flete], DESC))
```

## Medidas — Entregas y Satisfacción (Página 3)

```dax
Pedidos Entregados =
CALCULATE(COUNTROWS(olist_orders_dataset), olist_orders_dataset[order_status] = "delivered")

% Entregas Tardias = DIVIDE([Pedidos Tardios], [Pedidos Entregados])

-- Tiempo por etapa (validado contra SQL, ver hallazgo técnico en /docs)
Tiempo Entrega =
AVERAGEX(
    FILTER(olist_orders_dataset,
        olist_orders_dataset[order_status] = "delivered"
        && NOT(ISBLANK(olist_orders_dataset[order_delivered_customer_date]))
        && NOT(ISBLANK(olist_orders_dataset[order_delivered_carrier_date]))),
    olist_orders_dataset[order_delivered_customer_date] - olist_orders_dataset[order_delivered_carrier_date])
-- 9.33 días -- cuello de botella, 74.3% del ciclo total
```

## Medidas — Vendor Scorecard (Página 4)

```dax
Total Vendedores = DISTINCTCOUNT(olist_sellers_dataset[seller_id])

% Vendedores Estado =
DIVIDE(
    [Total Vendedores],
    CALCULATE([Total Vendedores], ALL(olist_sellers_dataset[seller_state]))
)

% Revenue Estado =
DIVIDE(
    [Revenue Total],
    CALCULATE([Revenue Total], ALL(olist_sellers_dataset[seller_state]))
)

Indice Eficiencia = DIVIDE([% Revenue Estado], [% Vendedores Estado])

Estado Mas Eficiente =
CALCULATE(
    SELECTEDVALUE(olist_sellers_dataset[seller_state]),
    TOPN(1, FILTER(ALL(olist_sellers_dataset[seller_state]), [Total Vendedores] >= 20),
        [Indice Eficiencia], DESC)
)
```

### Nota técnica — por qué `NOT(ISBLANK(...))` en las medidas de tiempo

SQL ignora los valores `NULL` automáticamente en funciones de agregación (`AVG()`, etc.). DAX **no** hace lo mismo: `AVERAGEX` trata un valor en blanco como `0` al restar fechas, lo que en el sistema interno de Power BI equivale al 30/12/1899 — generando diferencias de miles de días y arruinando el promedio. La solución es excluir blancos explícitamente con `NOT(ISBLANK(...))` para las dos columnas que participan en cada resta. Ver el hallazgo completo en [`docs/hallazgos_tecnicos.md`](../docs/hallazgos_tecnicos.md).
