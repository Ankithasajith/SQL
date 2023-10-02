SELECT
    CONCAT(EXTRACT(YEAR FROM ddate.date), '-', LPAD(EXTRACT(MONTH FROM ddate.date), 2, '0')) AS YearMonth,
    IF(dw.warehouse_type = "Sector", sfs.City, dw.City) AS City,
    sfs.State AS State,
    sfs.Warehouse AS Warehouse,
    sfs.Item_Code AS Item_Code,
    sfs.Item_Linkage AS Item_Linkage,
    SUM(sfs.amount) AS TotalSalesRevenue,
    LAG(SUM(sfs.amount)) OVER (PARTITION BY
        IF(dw.warehouse_type = "Sector", sfs.City, dw.City),
        sfs.State,
        sfs.Warehouse,
        sfs.Item_Code,
        sfs.Item_Linkage
        ORDER BY CONCAT(EXTRACT(YEAR FROM ddate.date), '-', LPAD(EXTRACT(MONTH FROM ddate.date), 2, '0'))
    ) AS PreviousMonthRevenue,
    TRY_DIVIDE(SUM(sfs.margin), SUM(sfs.amount_with_tax)) * 100 AS MarginPercentage
FROM
    core.salesfactsnapshot sfs
INNER JOIN
    core.dimdate ddate ON sfs.__date = ddate.date
LEFT JOIN
    core.dimwarehouse dw ON dw.active = 1 AND dw.name = sfs.set_warehouse
WHERE
    1 = 1
    AND UPPER(sfs.warehouse) NOT LIKE '%URBAN%'
    AND UPPER(sfs.warehouse) NOT LIKE '%KIRUN%'
    AND UPPER(sfs.warehouse) NOT LIKE '%DAMAGES%'
    AND UPPER(sfs.warehouse) NOT LIKE '%DISCARDED%'
    AND UPPER(sfs.warehouse) NOT LIKE '%EXPIRED%'
    AND UPPER(sfs.warehouse) NOT LIKE '%DARK%'
    AND sfs.derived_business_type = 'B2B Rural'
    AND sfs.er_item_type NOT IN ('General Merchandise', 'Oil', 'Sugar')
    AND LOWER(sfs.item_code) NOT LIKE '%supersaver%'
    AND sfs.item_code NOT LIKE '%_discount%'
    AND ddate.date BETWEEN DATE_ADD(CURRENT_DATE(), -90) AND CURRENT_DATE()
GROUP BY
    CONCAT(EXTRACT(YEAR FROM ddate.date), '-', LPAD(EXTRACT(MONTH FROM ddate.date), 2, '0')),
    IF(dw.warehouse_type = "Sector", sfs.City, dw.City),
    sfs.State,
    sfs.Warehouse,
    sfs.Item_Code,
    sfs.Item_Linkage
ORDER BY
    YearMonth;
