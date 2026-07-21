# Diccionario de Datos

El dataset está compuesto por 9 tablas relacionales del marketplace Olist (Brasil).

## olist_orders_dataset — tabla de eventos principal (99,441 filas)

| Columna | Tipo | Descripción |
|---|---|---|
| order_id | text (PK) | Identificador único del pedido |
| customer_id | text (FK) | Referencia al cliente — relación 1:1 con customers |
| order_status | text | 8 estados posibles (delivered, shipped, canceled, etc.) |
| order_purchase_timestamp | datetime | Fecha y hora de compra |
| order_approved_at | datetime | Fecha de aprobación de pago — nulos válidos por diseño |
| order_delivered_carrier_date | datetime | Fecha de entrega al transportista |
| order_delivered_customer_date | datetime | Fecha de entrega al cliente final |
| order_estimated_delivery_date | datetime | Fecha estimada — se genera siempre, sin excepción |

## olist_order_items_dataset — tabla de hechos transaccional (112,650 filas)

| Columna | Tipo | Descripción |
|---|---|---|
| order_id / order_item_id | text / int | Identifican pedido y línea de producto dentro del pedido |
| product_id / seller_id | text (FK) | Referencias a producto y vendedor |
| price | numeric | Precio unitario del producto |
| freight_value | numeric | Costo de flete asociado a la línea |

## olist_order_payments_dataset (103,886 filas)

| Columna | Descripción |
|---|---|
| order_id | FK — multi-fila por pedido (hasta 29 métodos distintos) |
| payment_type | 5 métodos posibles (credit_card, boleto, voucher, debit_card, not_defined) |
| payment_installments | Número de mensualidades |
| payment_value | Monto — incluye producto + flete |

## olist_order_reviews_dataset (99,224 filas)

| Columna | Descripción |
|---|---|
| review_score | Entero 1-5 |
| review_comment_title | 88% nulo — opcional |
| review_comment_message | 59% nulo — opcional |
| review_creation_date | Fecha de creación de la reseña |

## olist_customers_dataset

| Columna | Descripción |
|---|---|
| customer_id | Identificador por pedido — **no representa un cliente único** |
| customer_unique_id | Identificador real de cliente — usar para análisis de recurrencia |
| customer_state | Estado del cliente (2 letras) |

## olist_products_dataset (32,951 filas)

| Columna | Descripción |
|---|---|
| product_category_name | 610 productos sin categoría (1.85%) — reemplazado con "unclassified" |
| product_weight_g / length_cm / height_cm / width_cm | Dimensiones físicas del producto |

## olist_sellers_dataset (3,095 filas)

| Columna | Descripción |
|---|---|
| seller_id | Identificador único del vendedor |
| seller_state | Estado donde opera el vendedor |

## olist_geolocation_dataset (~1M filas)

Coordenadas por código postal. Perfilado limitado a 1,000 filas — el dataset completo congela Power Query.

## product_category_name_translation (71 filas)

Traducción portugués → inglés de las categorías de producto.
