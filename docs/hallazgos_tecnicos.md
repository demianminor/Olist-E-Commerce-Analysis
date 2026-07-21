# Hallazgos Técnicos

Documentación de los problemas reales encontrados durante el proyecto — causa raíz, diagnóstico y solución. Un análisis solo es auditable si su razonamiento queda documentado, no solo su resultado.

## 1. BLANK en DAX vs NULL en SQL

**Síntoma:** al crear las medidas DAX de tiempo por etapa (Página 3), `Tiempo de Aprobacion` arrojó **-5.14 días** — un resultado matemáticamente imposible (un pedido no puede aprobarse antes de comprarse).

**Causa raíz:** SQL y DAX manejan los valores en blanco de forma distinta en operaciones aritméticas:
- **SQL:** `AVG()` ignora los `NULL` automáticamente.
- **DAX:** `AVERAGEX` no ignora los blancos al restar fechas — los trata como `0`, equivalente al 30/12/1899 en el sistema de fechas de Power BI. Con 14 pedidos sin `order_approved_at`, la resta generó diferencias de +42,800 días, distorsionando el promedio de las 96,478 filas.

**Diagnóstico:** confirmado conectando directamente al modelo (Power BI MCP) y ordenando resultados con `TOPN` — los valores extremos coincidían exactamente con las filas de fecha en blanco.

**Solución:**
```dax
Tiempo de Aprobacion =
AVERAGEX(
    FILTER(olist_orders_dataset,
        olist_orders_dataset[order_status] = "delivered"
        && NOT(ISBLANK(olist_orders_dataset[order_approved_at]))
        && NOT(ISBLANK(olist_orders_dataset[order_purchase_timestamp]))),
    olist_orders_dataset[order_approved_at] - olist_orders_dataset[order_purchase_timestamp])
```

**Resultado tras la corrección:**

| Medida | Antes (con el error) | Después (validado contra SQL) |
|---|---|---|
| Tiempo de Aprobación | -5.78 | 0.43 |
| Tiempo Transportista | 8.12 | 2.80 |
| Tiempo Entrega | 6.64 | **9.33** (74.3% del ciclo — cuello de botella) |
| Tiempo Ciclo Total | 8.97 | 12.56 |

**Principio general:** SQL ignora `NULL` por default en funciones de agregación; DAX no — hay que excluirlos explícitamente con `ISBLANK()` cuando participan en una operación aritmética, o se cuelan como si fueran cero. Mismo principio en Excel: `SI(O(ESBLANCO(A2),ESBLANCO(B2)),"",B2-A2)` antes de promediar.

---

## 2. Filtro de Power Query dejado activo

**Síntoma:** la medida `Total Pedidos` mostraba un valor muy por debajo de lo esperado en el modelo.

**Causa raíz:** durante la auditoría de calidad se aplicó un filtro temporal en `orders` para validar pedidos cancelados. El filtro quedó activo por accidente al cerrar Power Query, reduciendo la tabla de 99,441 a 625 filas y contaminando silenciosamente todas las medidas dependientes.

**Detección:** contrastar `Total Pedidos` contra el conteo real en SQL — la discrepancia fue la señal de alarma.

**Lección:** siempre revisar los "Pasos Aplicados" en Power Query antes de cerrar y aplicar los cambios — un filtro activo reduce silenciosamente las filas cargadas al modelo, sin ningún error visible.

---

## 3. Índice de eficiencia — riesgo de muestra pequeña

**Contexto:** al calcular el índice de eficiencia por estado (`% revenue ÷ % vendedores`) para el Vendor Scorecard, el estado **MA** mostró el índice más alto de todos (8.29) — pero con **1 solo vendedor**.

**Investigación:** en vez de descartar el dato como ruido estadístico, se verificó el patrón de venta de ese vendedor:
```sql
SELECT COUNT(oi.order_id) AS total_pedidos,
       COUNT(DISTINCT DATE_TRUNC('month', o.order_purchase_timestamp)) AS meses_distintos
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi ON s.seller_id = oi.seller_id
JOIN olist_orders_dataset o ON oi.order_id = o.order_id
WHERE s.seller_state = 'MA'
GROUP BY s.seller_id;
```
**Resultado:** 405 pedidos en 8 de los 25 meses del proyecto — un patrón de venta real y sostenido, no un pedido atípico.

**Conclusión:** el índice alto de MA es un hallazgo de negocio legítimo (dependencia total en un solo vendedor = riesgo de concentración), no un error de datos. Regla aplicada al resto del análisis: estados con menos de 20 vendedores se excluyen del ranking comparativo, porque con muestras tan chicas un solo caso puede distorsionar el resultado sin representar un patrón generalizable.
