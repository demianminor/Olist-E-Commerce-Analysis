# Modelo de Datos

Antes de construir cualquier JOIN se generó un mapa de relaciones entre tablas. El modelo sigue un **star schema**, con `olist_order_items_dataset` como tabla de hechos principal.

## Vista de Modelo (Power BI)

![Modelo de datos en Power BI](../screenshots/05_model_diagram.png)

## Diagrama de relaciones (texto)

```
[FACT] order_items  (price, freight_value)
   |── order_id      → [FACT] orders  (fechas, status) — ambas direcciones
   │                        ├── customer_id → [DIM] customers (1:1, ambas)
   │                        └── purchase_timestamp → [DIM] Calendario (única)
   ├── product_id    → [DIM] products  — ambas
   │                        └── category_name → [DIM] category_translation — ambas
   └── seller_id     → [DIM] sellers  — única

[FACT sec.] order_payments → orders.order_id (única)
[FACT sec.] order_reviews  → orders.order_id (única · Many-to-One)
[DIM] geolocation — desconectada, uso futuro en mapas
```

## Roles de cada tabla en el modelo

| Tabla | Rol | Nota |
|---|---|---|
| order_items | Tabla de hechos principal | Contiene price y freight_value |
| orders | Factless fact table | Fechas y status, sin métricas numéricas |
| customers / products / sellers | Dimensiones | Atributos descriptivos |
| order_payments / order_reviews | Tablas de hechos secundarias | Multi-fila por pedido |
| category_translation | Dimensión de traducción | Portugués → inglés, 71 categorías |
| Calendario | Tabla de fechas oficial | Creada con `CALENDARAUTO()` en DAX |

## Decisiones de modelado

**Por qué una tabla Calendario dedicada.** Se creó con `CALENDARAUTO()`, detectando automáticamente el rango de fechas del modelo. Sin una tabla de fechas dedicada, Power BI no puede ejecutar inteligencia de tiempo — comparaciones año contra año, acumulados, tendencias mensuales continuas.

**Corrección de documentación previa.** Se verificó vía conexión directa al modelo (Power BI MCP) que la relación `order_reviews → orders` es Many-to-One directa, sin pasar por `order_items` como se documentó inicialmente en una versión temprana del ERD. El punto fue relevante para construir correctamente el cálculo de reseñas por etapa de entrega en Página 3.

**Por qué no se modeló `geolocation` conectada.** El volumen (~1M filas) y la granularidad por código postal no aportaban al análisis de negocio priorizado en este proyecto — se dejó como tabla de referencia desconectada, disponible para una futura iteración con mapas de calor geográficos.
