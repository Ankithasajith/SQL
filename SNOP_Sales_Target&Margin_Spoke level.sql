WITH ilv_niyojanplanninglinkage AS
(
    SELECT
        item_linkage,
        CASE WHEN item_linkage LIKE '%Bambino%' THEN item_linkage ELSE planning_linkage END AS planning_linkage
    FROM dsapps_staging.dwniyojanplanninglinkage
    WHERE active = 1
),
ilv_wh_status AS
(
    SELECT
        DISTINCT source_warehouse,
        hub_warehouse,
        IF(MAX(Active_Days_in_last_7_days) > 0, "ACTIVE", "INACTIVE") AS active_status
    FROM core.activewarehouselist
    LEFT JOIN core.dimwarehouse dw ON dw.name = activewarehouselist.source_warehouse
    WHERE dw.active = 1 AND dw.warehouse_type = "Main" AND Active_Days_in_last_7_days > 0
    GROUP BY source_warehouse, hub_warehouse
),

distinct_dimitem AS (
    SELECT
        max(brand) as brand,
        max(er_item_type) as er_item_type,
        item_linkage
    FROM core.dimitem
    WHERE active = 1
    GROUP BY  item_linkage
),
distinct_dimwarehouse AS (
    SELECT DISTINCT
        name,
        city,
        state
    FROM core.dimwarehouse
    WHERE active = 1
)

SELECT
    stj.warehouse,
    ilv_npl.planning_linkage,
    di.brand,
    di.er_item_type,
    dw.state,
    dw.city,
    ilv_wh.hub_warehouse AS replenishment_centre,
    stj.snop_target_july as sales_target,
    snop_target_july*margin_pct/100 AS total_margin,
    stj.margin_pct as margin_percentage,
    -- Add new column to be included in the GROUP BY to remove duplicates
    CONCAT(stj.warehouse, '_', ilv_npl.planning_linkage, '_', di.brand) AS ilv_required_column

FROM  adhoc_dev.snop_target_july stj
LEFT JOIN distinct_dimitem di ON stj.item_linkage = di.item_linkage
LEFT JOIN distinct_dimwarehouse dw ON stj.warehouse = dw.name
LEFT JOIN ilv_niyojanplanninglinkage ilv_npl ON stj.item_linkage = ilv_npl.item_linkage
LEFT JOIN ilv_wh_status ilv_wh ON stj.warehouse = ilv_wh.source_warehouse
ORDER BY sales_target DESC;