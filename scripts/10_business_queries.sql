/*
===============================================================================
Business Queries - Example Analytical Queries Against the Gold Layer
===============================================================================
A set of example business questions answered against the Gold dimensional
model (gold.dim_customer, gold.dim_product, gold.dim_seller, gold.dim_date,
gold.fact_orders, gold.fact_order_items, gold.fact_order_payments,
gold.fact_order_reviews).

Demonstrates aggregations, multi-table joins and window functions
(RANK / DENSE_RANK / ROW_NUMBER, LAG, moving averages, NTILE, SUM() OVER()).

Revenue, spend and payment-value queries (1-4, 9, 10, 12, 13) and the
repeat-customer query (8) keep only rows with IsCompletedSale = 1, i.e. they
exclude orders with status 'canceled' or 'unavailable', because these orders
did not produce a completed sale.
Logistics and review queries keep all orders, because they describe
deliveries and reviews, not sales.
The flag is stored in fact_orders, fact_order_items and fact_order_payments
(see gold.LoadData), so revenue queries filter the fact table they read and
need no fact-to-fact join through OrderId. Queries 7 and 11 still join
fact_orders by OrderId, because they need order-level measures such as
DeliveryDays and IsLate.

This script is meant to be run manually for ad-hoc analysis and is not part
of run_pipeline.sql / run_pipeline.bat.
===============================================================================
*/

USE OlistDWH;
GO

/* ============================================================================
   SALES & REVENUE
============================================================================ */

/* ----------------------------------------------------------------------------
   1) Monthly revenue and order count, with month-over-month % change
---------------------------------------------------------------------------- */

WITH MonthlyRevenue AS (
    SELECT
        d.Year,
        d.Month,
        SUM(oi.Price + oi.FreightValue) AS TotalRevenue,
        COUNT(DISTINCT oi.OrderId) AS OrderCount
    FROM gold.fact_order_items oi
    JOIN gold.dim_date d ON oi.PurchaseDateKey = d.DateKey
    WHERE oi.IsCompletedSale = 1
    GROUP BY d.Year, d.Month
)
SELECT
    Year,
    Month,
    TotalRevenue,
    OrderCount,
    LAG(TotalRevenue) OVER (ORDER BY Year, Month) AS PrevMonthRevenue,
    CAST(
        100.0 * (TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY Year, Month))
        / NULLIF(LAG(TotalRevenue) OVER (ORDER BY Year, Month), 0)
        AS DECIMAL(10, 2)
    ) AS RevenueChangePct
FROM MonthlyRevenue
ORDER BY Year, Month;
GO

/* ----------------------------------------------------------------------------
   2) Top 3 product categories by revenue, per quarter
---------------------------------------------------------------------------- */

WITH CategoryQuarterRevenue AS (
    SELECT
        d.Year,
        d.Quarter,
        p.CategoryNameEnglish AS CategoryName,
        SUM(oi.Price) AS CategoryRevenue
    FROM gold.fact_order_items oi
    JOIN gold.dim_product p ON oi.ProductKey = p.ProductKey
    JOIN gold.dim_date d ON oi.PurchaseDateKey = d.DateKey
    WHERE oi.IsCompletedSale = 1
    GROUP BY d.Year, d.Quarter, p.CategoryNameEnglish
),
RankedCategories AS (
    SELECT
        Year,
        Quarter,
        CategoryName,
        CategoryRevenue,
        RANK() OVER (
            PARTITION BY Year, Quarter
            ORDER BY CategoryRevenue DESC
        ) AS RevenueRank
    FROM CategoryQuarterRevenue
)
SELECT Year, Quarter, CategoryName, CategoryRevenue, RevenueRank
FROM RankedCategories
WHERE RevenueRank <= 3
ORDER BY Year, Quarter, RevenueRank;
GO

/* ----------------------------------------------------------------------------
   3) Monthly Average Order Value (AOV) with a 3-month moving average
---------------------------------------------------------------------------- */

WITH MonthlyAOV AS (
    SELECT
        d.Year,
        d.Month,
        SUM(oi.Price + oi.FreightValue) / COUNT(DISTINCT oi.OrderId) AS AvgOrderValue
    FROM gold.fact_order_items oi
    JOIN gold.dim_date d ON oi.PurchaseDateKey = d.DateKey
    WHERE oi.IsCompletedSale = 1
    GROUP BY d.Year, d.Month
)
SELECT
    Year,
    Month,
    CAST(AvgOrderValue AS DECIMAL(10, 2)) AS AvgOrderValue,
    CAST(
        AVG(AvgOrderValue) OVER (
            ORDER BY Year, Month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS DECIMAL(10, 2)
    ) AS MovingAvg3Month
FROM MonthlyAOV
ORDER BY Year, Month;
GO

/* ----------------------------------------------------------------------------
   4) Revenue by customer state
---------------------------------------------------------------------------- */

SELECT
    c.State,
    COUNT(DISTINCT oi.OrderId) AS OrderCount,
    SUM(oi.Price + oi.FreightValue) AS TotalRevenue
FROM gold.fact_order_items oi
JOIN gold.dim_customer c ON oi.CustomerKey = c.CustomerKey
WHERE oi.IsCompletedSale = 1
GROUP BY c.State
ORDER BY TotalRevenue DESC;
GO

/* ============================================================================
   LOGISTICS & DELIVERY
============================================================================ */

/* ----------------------------------------------------------------------------
   5) Late delivery rate per month
   (Restricted to delivered orders - IsLate is NULL for orders that have not
   been delivered yet, so including them in the denominator would understate
   the rate without ever being able to count toward the numerator.)
---------------------------------------------------------------------------- */

SELECT
    d.Year,
    d.Month,
    COUNT(*) AS DeliveredOrders,
    SUM(CASE WHEN f.IsLate = 1 THEN 1 ELSE 0 END) AS LateOrders,
    CAST(
        100.0 * SUM(CASE WHEN f.IsLate = 1 THEN 1 ELSE 0 END) / COUNT(*)
        AS DECIMAL(5, 2)
    ) AS LateOrderPct
FROM gold.fact_orders f
JOIN gold.dim_date d ON f.PurchaseDateKey = d.DateKey
WHERE f.IsDelivered = 1
GROUP BY d.Year, d.Month
ORDER BY d.Year, d.Month;
GO

/* ----------------------------------------------------------------------------
   6) Average delivery time by customer state
---------------------------------------------------------------------------- */

SELECT
    c.State,
    COUNT(*) AS DeliveredOrders,
    CAST(AVG(CAST(f.DeliveryDays AS FLOAT)) AS DECIMAL(6, 2)) AS AvgDeliveryDays
FROM gold.fact_orders f
JOIN gold.dim_customer c ON f.CustomerKey = c.CustomerKey
WHERE f.IsDelivered = 1
GROUP BY c.State
ORDER BY AvgDeliveryDays DESC;
GO

/* ----------------------------------------------------------------------------
   7) Average review score by delivery outcome (on-time vs late)
---------------------------------------------------------------------------- */

/*
Some orders have more than one review. Review scores are first averaged per
order, so that each order counts once in the result.
*/
WITH OrderScores AS (
    SELECT
        r.OrderId,
        AVG(CAST(r.ReviewScore AS FLOAT)) AS OrderScore
    FROM gold.fact_order_reviews r
    GROUP BY r.OrderId
)
SELECT
    CASE WHEN f.IsLate = 1 THEN 'Late' ELSE 'On time' END AS DeliveryOutcome,
    COUNT(*) AS ReviewedOrders,
    CAST(AVG(os.OrderScore) AS DECIMAL(4, 2)) AS AvgReviewScore
FROM gold.fact_orders f
JOIN OrderScores os ON f.OrderId = os.OrderId
WHERE f.IsDelivered = 1
GROUP BY CASE WHEN f.IsLate = 1 THEN 'Late' ELSE 'On time' END;
GO

/* ============================================================================
   CUSTOMERS
============================================================================ */

/* ----------------------------------------------------------------------------
   8) One-time vs repeat customers
---------------------------------------------------------------------------- */

WITH CustomerOrderCounts AS (
    SELECT
        CustomerKey,
        COUNT(*) AS OrdersPlaced
    FROM gold.fact_orders
    WHERE IsCompletedSale = 1
    GROUP BY CustomerKey
)
SELECT
    CASE WHEN OrdersPlaced = 1 THEN 'One-time' ELSE 'Repeat' END AS CustomerType,
    COUNT(*) AS CustomerCount,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5, 2)) AS PctOfCustomers
FROM CustomerOrderCounts
GROUP BY CASE WHEN OrdersPlaced = 1 THEN 'One-time' ELSE 'Repeat' END;
GO

/* ----------------------------------------------------------------------------
   9) Top 10 customers by total spend (simplified LTV)
---------------------------------------------------------------------------- */

WITH CustomerSpend AS (
    SELECT
        c.CustomerKey,
        c.CustomerUniqueId,
        c.State,
        SUM(oi.Price + oi.FreightValue) AS TotalSpend,
        COUNT(DISTINCT oi.OrderId) AS OrderCount
    FROM gold.fact_order_items oi
    JOIN gold.dim_customer c ON oi.CustomerKey = c.CustomerKey
    WHERE oi.IsCompletedSale = 1
    GROUP BY c.CustomerKey, c.CustomerUniqueId, c.State
)
SELECT TOP 10
    CustomerUniqueId,
    State,
    OrderCount,
    TotalSpend,
    ROW_NUMBER() OVER (ORDER BY TotalSpend DESC) AS SpendRank
FROM CustomerSpend
ORDER BY TotalSpend DESC;
GO

/* ============================================================================
   SELLERS
============================================================================ */

/* ----------------------------------------------------------------------------
   10) Top 10 sellers by revenue
---------------------------------------------------------------------------- */

WITH SellerRevenue AS (
    SELECT
        s.SellerId,
        s.State,
        SUM(oi.Price) AS TotalRevenue,
        COUNT(DISTINCT oi.OrderId) AS OrderCount
    FROM gold.fact_order_items oi
    JOIN gold.dim_seller s ON oi.SellerKey = s.SellerKey
    WHERE s.SellerKey <> -1
      AND oi.IsCompletedSale = 1
    GROUP BY s.SellerId, s.State
)
SELECT TOP 10
    SellerId,
    State,
    OrderCount,
    TotalRevenue,
    DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
FROM SellerRevenue
ORDER BY TotalRevenue DESC;
GO

/* ----------------------------------------------------------------------------
   11) Seller delivery performance vs average review score
   (Only sellers with at least 10 orders are included, to keep the ranking
   meaningful and avoid noise from one-off sellers. Order items are first
   reduced to distinct (OrderId, SellerKey) pairs before joining to the
   order-grain fact_orders/fact_order_reviews tables, so a seller's
   multi-item orders are not counted more than once in the averages below.
   Review scores are also averaged per order first, so an order with several
   reviews counts once.)
---------------------------------------------------------------------------- */

WITH SellerOrders AS (
    SELECT DISTINCT
        oi.OrderId,
        oi.SellerKey
    FROM gold.fact_order_items oi
    WHERE oi.SellerKey <> -1
),
OrderScores AS (
    -- One row per order: an order with several reviews counts once.
    SELECT
        r.OrderId,
        AVG(CAST(r.ReviewScore AS FLOAT)) AS OrderScore
    FROM gold.fact_order_reviews r
    GROUP BY r.OrderId
),
SellerPerformance AS (
    SELECT
        s.SellerId,
        AVG(CAST(f.DeliveryDays AS FLOAT)) AS AvgDeliveryDays,
        AVG(os.OrderScore) AS AvgReviewScore,
        COUNT(DISTINCT so.OrderId) AS OrderCount
    FROM SellerOrders so
    JOIN gold.dim_seller s ON so.SellerKey = s.SellerKey
    JOIN gold.fact_orders f ON so.OrderId = f.OrderId
    LEFT JOIN OrderScores os ON so.OrderId = os.OrderId
    WHERE f.IsDelivered = 1
    GROUP BY s.SellerId
    HAVING COUNT(DISTINCT so.OrderId) >= 10
)
SELECT
    SellerId,
    OrderCount,
    CAST(AvgDeliveryDays AS DECIMAL(6, 2)) AS AvgDeliveryDays,
    CAST(AvgReviewScore AS DECIMAL(4, 2)) AS AvgReviewScore,
    RANK() OVER (ORDER BY AvgDeliveryDays DESC) AS SlowestDeliveryRank
FROM SellerPerformance
ORDER BY AvgDeliveryDays DESC;
GO

/* ============================================================================
   PAYMENTS
============================================================================ */

/* ----------------------------------------------------------------------------
   12) Payment method distribution and share of total revenue
---------------------------------------------------------------------------- */

SELECT
    PaymentType,
    COUNT(*) AS PaymentCount,
    SUM(PaymentValue) AS TotalValue,
    CAST(
        100.0 * SUM(PaymentValue) / SUM(SUM(PaymentValue)) OVER ()
        AS DECIMAL(5, 2)
    ) AS PctOfTotalRevenue
FROM gold.fact_order_payments op
WHERE op.IsCompletedSale = 1
GROUP BY PaymentType
ORDER BY TotalValue DESC;
GO

/* ----------------------------------------------------------------------------
   13) Average installment count by order-value quartile
---------------------------------------------------------------------------- */

WITH OrderValue AS (
    SELECT
        op.OrderId,
        SUM(op.PaymentValue) AS OrderValue,
        AVG(CAST(op.PaymentInstallments AS FLOAT)) AS AvgInstallments
    FROM gold.fact_order_payments op
    WHERE op.IsCompletedSale = 1
    GROUP BY op.OrderId
),
OrderValueQuartiles AS (
    SELECT
        OrderId,
        OrderValue,
        AvgInstallments,
        NTILE(4) OVER (ORDER BY OrderValue) AS ValueQuartile
    FROM OrderValue
)
SELECT
    ValueQuartile,
    COUNT(*) AS OrderCount,
    CAST(MIN(OrderValue) AS DECIMAL(10, 2)) AS MinOrderValue,
    CAST(MAX(OrderValue) AS DECIMAL(10, 2)) AS MaxOrderValue,
    CAST(AVG(AvgInstallments) AS DECIMAL(4, 2)) AS AvgInstallments
FROM OrderValueQuartiles
GROUP BY ValueQuartile
ORDER BY ValueQuartile;
GO

/* ============================================================================
   CUSTOMER SATISFACTION (REVIEWS)
============================================================================ */

/* ----------------------------------------------------------------------------
   14a) Review score distribution
---------------------------------------------------------------------------- */

SELECT
    ReviewScore,
    COUNT(*) AS ReviewCount,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5, 2)) AS PctOfReviews
FROM gold.fact_order_reviews
GROUP BY ReviewScore
ORDER BY ReviewScore;
GO

/* ----------------------------------------------------------------------------
   14b) Average review score per month, with month-over-month change
---------------------------------------------------------------------------- */

WITH MonthlyScore AS (
    SELECT
        d.Year,
        d.Month,
        AVG(CAST(r.ReviewScore AS FLOAT)) AS AvgScore
    FROM gold.fact_order_reviews r
    JOIN gold.dim_date d ON r.ReviewCreationDateKey = d.DateKey
    GROUP BY d.Year, d.Month
)
SELECT
    Year,
    Month,
    CAST(AvgScore AS DECIMAL(4, 2)) AS AvgScore,
    CAST(
        AvgScore - LAG(AvgScore) OVER (ORDER BY Year, Month)
        AS DECIMAL(4, 2)
    ) AS ScoreChangeVsPrevMonth
FROM MonthlyScore
ORDER BY Year, Month;
GO

/* ----------------------------------------------------------------------------
   15) Product categories with the lowest average review scores
   (Categories with fewer than 30 reviews are excluded to avoid noisy
   averages from very small samples. Joining reviews to order items means a
   multi-category order's review counts once per category it contains.)
---------------------------------------------------------------------------- */

WITH CategoryScores AS (
    SELECT
        p.CategoryNameEnglish AS CategoryName,
        AVG(CAST(r.ReviewScore AS FLOAT)) AS AvgReviewScore,
        COUNT(*) AS ReviewCount
    FROM gold.fact_order_reviews r
    JOIN gold.fact_order_items oi ON r.OrderId = oi.OrderId
    JOIN gold.dim_product p ON oi.ProductKey = p.ProductKey
    GROUP BY p.CategoryNameEnglish
    HAVING COUNT(*) >= 30
)
SELECT
    CategoryName,
    ReviewCount,
    CAST(AvgReviewScore AS DECIMAL(4, 2)) AS AvgReviewScore,
    RANK() OVER (ORDER BY AvgReviewScore ASC) AS WorstScoreRank
FROM CategoryScores
ORDER BY AvgReviewScore ASC;
GO
