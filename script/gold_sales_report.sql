/*
===============================================================================
View: gold.sales_report
Grain: Month x Country x Category x Subcategory x Brand

Purpose:
- Provide a clean, monthly level dataset for the Eurozone E-Commerce
  Executive Dashboard.
- Expose the five core KPIs used in the dashboards:
    1) Total Sales (net_revenue)
    2) Units Sold (units)
    3) Profit (net_profit)
    4) Average Price (aur)
    5) Profit Ratio (margin_pct)
- Include previous year values and absolute YoY deltas for each KPI so that
  Tableau can compute YoY % and build all visual stories.

Notes:
- Data is returned at monthly grain for 2023 and 2024 only.
- All comparisons are year over year (same month previous year).
- Additional visual logic (YoY %, outlier flags, decomposition bars, etc.) is
  implemented in Tableau, not in this view.
===============================================================================
*/

GO

IF OBJECT_ID('gold.sales_report', 'V') IS NOT NULL
    DROP VIEW gold.sales_report;
GO

CREATE VIEW gold.sales_report AS
WITH result AS (
    -- Line level inputs with month, geography, and product attributes
    SELECT
        DATEFROMPARTS(f.date_key / 10000, (f.date_key / 100) % 100, 1) AS month_start_date,
        a.country_code,
        a.country,
        p.category,
        p.sub_category,
        p.brand,
        CAST(f.quantity      AS BIGINT)        AS quantity,
        CAST(f.sales_amount  AS DECIMAL(18,2)) AS revenue_line,
        CAST(f.cost_amount   AS DECIMAL(18,2)) AS cogs_line,
        CAST(
            CASE WHEN f.is_cancelled = 1 OR f.is_returned = 1
                 THEN 0 ELSE f.sales_amount
            END AS DECIMAL(18,2)
        ) AS net_revenue_line,
        CAST(
            CASE WHEN f.is_cancelled = 1 OR f.is_returned = 1
                 THEN 0 ELSE f.profit_amount
            END AS DECIMAL(18,2)
        ) AS net_profit_line
    FROM gold.fact_sales f
    JOIN gold.dim_address a ON f.address_key = a.address_key
    JOIN gold.dim_product p ON f.product_key  = p.product_key
), intermediate_result AS (
    -- Aggregate to month x country x category x subcategory x brand
    SELECT
        month_start_date,
        country_code,
        country,
        category,
        sub_category,
        brand,
        SUM(revenue_line)     AS revenue,      -- gross sales
        SUM(net_revenue_line) AS net_revenue,  -- Total Sales KPI
        SUM(quantity)         AS units,        -- Units Sold KPI
        SUM(cogs_line)        AS cogs,
        SUM(net_profit_line)  AS net_profit    -- Profit KPI
    FROM result
    GROUP BY
        month_start_date,
        country_code,
        country,
        category,
        sub_category,
        brand
), final_result AS (
    -- Add ratios and YoY (previous year value + absolute delta) for all 5 KPIs
    SELECT
        ir.month_start_date,
        DATEPART(year, ir.month_start_date) AS [year],
        CAST(FORMAT(ir.month_start_date, 'yyyyMM') AS INT) AS year_month,

        ir.country_code,
        ir.country,
        ir.category,
        ir.sub_category,
        ir.brand,

        -- Core metrics
        ir.revenue,
        ir.net_revenue,                                                 -- Total Sales
        ir.units,                                                       -- Units Sold
        ir.cogs,
        ir.net_profit,                                                  -- Profit
        CAST(
            ir.net_profit / NULLIF(ir.net_revenue, 0)
            AS DECIMAL(9,4)
        ) AS margin_pct,                                                -- Profit Ratio
        CAST(
            ir.revenue / NULLIF(ir.units, 0)
            AS DECIMAL(18,4)
        ) AS aur,                                                       -- Average Price (AUR)

        /* ========================
           YoY: Total Sales (net_revenue)
           ======================== */
        LAG(ir.net_revenue, 12) OVER (
            PARTITION BY ir.country_code, ir.brand
            ORDER BY ir.month_start_date
        ) AS prev_year_net_revenue,
        ir.net_revenue
        - LAG(ir.net_revenue, 12) OVER (
            PARTITION BY ir.country_code, ir.brand
            ORDER BY ir.month_start_date
        ) AS yoy_net_revenue_delta,

        /* ========================
           YoY: Units Sold
           ======================== */
        LAG(ir.units, 12) OVER (
            PARTITION BY ir.country_code, ir.brand
            ORDER BY ir.month_start_date
        ) AS prev_year_units,
        ir.units
        - LAG(ir.units, 12) OVER (
            PARTITION BY ir.country_code, ir.brand
            ORDER BY ir.month_start_date
        ) AS yoy_units_delta,

        /* ========================
           YoY: Profit
           ======================== */
        LAG(ir.net_profit, 12) OVER (
            PARTITION BY ir.country_code, ir.brand
            ORDER BY ir.month_start_date
        ) AS prev_year_net_profit,
        ir.net_profit
        - LAG(ir.net_profit, 12) OVER (
            PARTITION BY ir.country_code, ir.brand
            ORDER BY ir.month_start_date
        ) AS yoy_net_profit_delta,

        /* ========================
           YoY: Average Price (AUR)
           ======================== */
        LAG(
            CAST(ir.revenue / NULLIF(ir.units, 0) AS DECIMAL(18,4)),
            12
        ) OVER (
            PARTITION BY ir.country_code, ir.brand
            ORDER BY ir.month_start_date
        ) AS prev_year_aur,
        CAST(ir.revenue / NULLIF(ir.units, 0) AS DECIMAL(18,4))
        - LAG(
            CAST(ir.revenue / NULLIF(ir.units, 0) AS DECIMAL(18,4)),
            12
        ) OVER (
            PARTITION BY ir.country_code, ir.brand
            ORDER BY ir.month_start_date
        ) AS yoy_aur_delta,

        /* ========================
           YoY: Profit Ratio (Margin %)
           ======================== */
        LAG(
            CAST(ir.net_profit / NULLIF(ir.net_revenue, 0) AS DECIMAL(9,4)),
            12
        ) OVER (
            PARTITION BY ir.country_code, ir.brand
            ORDER BY ir.month_start_date
        ) AS prev_year_margin_pct,
        CAST(ir.net_profit / NULLIF(ir.net_revenue, 0) AS DECIMAL(9,4))
        - LAG(
            CAST(ir.net_profit / NULLIF(ir.net_revenue, 0) AS DECIMAL(9,4)),
            12
        ) OVER (
            PARTITION BY ir.country_code, ir.brand
            ORDER BY ir.month_start_date
        ) AS yoy_margin_pct_delta
    FROM intermediate_result ir
)
SELECT *
FROM final_result
WHERE [year] IN (2023, 2024);
GO
