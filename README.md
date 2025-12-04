# Eurozone E-Commerce - SQL Analysis Layer

This repository contains the SQL analysis layer that supports the
[`eurozone-ecommerce-ssql-data-warehouse`](https://github.com/onurkisa/eurozone-ecommerce-sql-data-warehouse)
project and powers the Eurozone E-Commerce Sales Dashboard (Overview and
Category Analysis pages).

The goal of this layer is to provide a clean, monthly level dataset containing
the five core KPIs used throughout the dashboard:

1. Total Sales (Revenue)
2. Units Sold
3. Profit
4. Average Price (AUR)
5. Profit Ratio (Margin %)

All additional visual logic, transformations, and analytical comparisons are
implemented directly in Tableau on top of these core fields.

---

## Business Requirements (Management Request)

The executive team wants to better understand how sales are performing across
Eurozone markets. Existing reports do not provide intuitive year over year
comparisons or deeper drill downs into categories, brands, and regional
performance.

**Requested dashboard capabilities**

- Clear view of overall performance (Sales, Profit, Units, Margin) for 2024
  compared to 2023.
- Ability to analyze monthly trends and identify periods of acceleration or
  slowdown.
- Visibility into which countries or regions are performing above or below
  expectations.
- Insights into categories, subcategories, and brands to understand which
  parts of the portfolio drive results.
- The ability to distinguish whether changes are price driven, volume driven,
  or margin driven.

**Key Executive Questions**

- How did we perform in 2024 compared to 2023?
- Which countries, regions, categories, or brands contributed most to growth
  or decline?
- Are results driven by price, volume, or margin dynamics?

The SQL model in this repository is designed to support these questions at a
monthly x country x category x subcategory x brand grain. Region is created in
Tableau by grouping countries.

---

## SQL and Tableau Integration Approaches

There are two architectural approaches that can be followed when designing the
analytics layer for this project:

### 1. Comprehensive SQL Approach  
Most analytical logic is pushed into SQL.  
This includes the five core KPIs together with supporting fields such as
previous year values, YoY deltas, decomposition ready fields, and other
pre-aggregated metrics that Tableau can consume directly.

### 2. Minimal SQL With Tableau-Driven Analytics (Chosen Approach)  
SQL provides only the core KPIs and essential dimensions at monthly level.  
All analytical calculations such as YoY percent change, growth metrics, trend
logic, and so on are performed inside Tableau.

This project intentionally uses **Approach 2** to keep the SQL layer clean,
maintainable, and reusable, while allowing Tableau full flexibility to compute
and visualize all analytic scenarios.

---

## Files in This Repository

- `script/gold_sales_report.sql`  
  Creates the `gold.sales_report` view in the warehouse.  
  Grain: Month x Country x Category x Subcategory x Brand.  
  Contains:
  - Dimensions: month, country, category, subcategory, brand  
  - Core metrics: Total Sales (net revenue), Units Sold (units), Profit
    (net_profit), Average Price (AUR), Profit Ratio (margin_pct), and COGS
  - Previous year values and YoY absolute deltas for each of the five KPIs

---

## Tableau Dashboard

The view created by `gold_sales_report.sql` is used as the primary data source
for the following Tableau dashboards:


