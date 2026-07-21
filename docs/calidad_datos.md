# Calidad de Datos

Antes de construir cualquier visual o medida se verificó la confiabilidad de los datos, bajo el principio de que un dashboard construido sobre datos sucios entrega respuestas incorrectas. La auditoría se ejecutó con las tres herramientas nativas de Power Query, configurando el profiling sobre el **dataset completo** — no solo la muestra por default de 1,000 filas.

## Metodología

| Herramienta | Qué revela |
|---|---|
| Column Quality | Porcentaje de valores válidos, con error o vacíos por columna |
| Column Distribution | Valores distintos vs. únicos — verifica si una columna es realmente llave primaria |
| Column Profile | Mínimo, máximo, promedio y desviación estándar — detecta valores fuera de rango |

## Las cuatro dimensiones evaluadas en cada tabla

| Dimensión | Pregunta que responde |
|---|---|
| Completeness | ¿Hay nulos donde no debería haberlos? |
| Uniqueness | ¿La llave primaria es realmente única? |
| Validity | ¿Los tipos de dato son correctos? |
| Accuracy | ¿Hay valores imposibles o fuera de rango? |

## Resultado de la auditoría — síntesis por tabla

| Tabla | Hallazgo principal | Decisión tomada |
|---|---|---|
| customers | Limpia · customer_unique_id: distintos ≠ únicos | Válido por diseño — ~3K clientes con recompra |
| geolocation | ~1M filas congela el profiling completo | Perfilado limitado a 1,000 filas — documentado |
| order_items | 3 registros con price = R$0.85 · 383 con flete = 0 | Se mantienen — impacto mínimo en el análisis |
| payments | Multi-fila por pedido por diseño | Siempre usar SUM(), nunca COUNT() de filas |
| reviews | 88% nulo en título · 59% en mensaje · 551 duplicados | Nulos válidos por diseño · duplicados deduplicados por fecha más reciente |
| orders | Nulos en fechas de entrega intermedias | Válidos por diseño — pedidos cancelados o en tránsito |
| products | 610 productos sin categoría (1.85%) | Reemplazados con "unclassified" |
| sellers / translation | Limpias | Sin acción requerida |

## Hallazgos destacados

**Nulos en fechas de cancelación — no son errores, son la huella del proceso.** Al filtrar por `order_status = 'canceled'`, el patrón de fechas presentes/ausentes revela en qué etapa se canceló cada pedido:

| Etapa | % con fecha | Interpretación |
|---|---|---|
| Aprobación | 77% | 23% cancelados antes de ser aprobados |
| Transportista | 12% | Solo 12% llegó al transportista antes de cancelarse |
| Entrega al cliente | <1% | Casos rarísimos — posible error de captura |

**Reseñas duplicadas (551 filas).** `olist_order_reviews_dataset` tiene 551 filas duplicadas por `order_id`. Sin deduplicar, cualquier JOIN con `orders` infla los conteos. Solución: quedarse con la reseña más reciente (`MAX(review_creation_date)`), vía CTE en SQL y `RELATEDTABLE + VAR` en DAX.

**Filtro de Power Query dejado activo.** Un filtro temporal aplicado durante la auditoría (para validar cancelados) quedó activo por accidente al cerrar Power Query, reduciendo `orders` de 99,441 a 625 filas sin ningún error visible. Detectado al contrastar `Total Pedidos` contra el conteo real en SQL. Ver detalle completo en [`hallazgos_tecnicos.md`](hallazgos_tecnicos.md).
