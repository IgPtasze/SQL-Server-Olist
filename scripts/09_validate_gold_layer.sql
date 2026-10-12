/*
===============================================================================
Stored Procedure: Validate Gold Layer
===============================================================================
Validates the data loaded into the Gold layer.

The procedure checks row counts, required fields, referential integrity,
duplicate keys, business logic and date dimension values.
===============================================================================
*/

CREATE OR ALTER PROCEDURE gold.ValidateData AS
BEGIN

    SET NOCOUNT ON;

    /* ============================================================================
       1) Row Count Checks
    ============================================================================ */

    SELECT
        'Row Count' AS TestName,
        'dim_customer' AS TableName,
        CASE WHEN COUNT(*) = (SELECT COUNT(DISTINCT CustomerUniqueId) FROM silver.Customers)
             THEN 'PASS' ELSE 'FAIL' END AS Status,
        ABS(COUNT(*) - (SELECT COUNT(DISTINCT CustomerUniqueId) FROM silver.Customers)) AS IssueCount,
        CONCAT(
            'Silver: ', (SELECT COUNT(DISTINCT CustomerUniqueId) FROM silver.Customers),
            ', Gold: ', COUNT(*)
        ) AS Details
    FROM gold.dim_customer

    UNION ALL

    SELECT
        'Row Count',
        'dim_product',
        CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM silver.Products)
             THEN 'PASS' ELSE 'FAIL' END,
        ABS(COUNT(*) - (SELECT COUNT(*) FROM silver.Products)),
        CONCAT(
            'Silver: ', (SELECT COUNT(*) FROM silver.Products),
            ', Gold: ', COUNT(*)
        )
    FROM gold.dim_product

    UNION ALL

    SELECT
        'Row Count',
        'dim_seller',
        CASE WHEN COUNT(*) - 1 = (SELECT COUNT(*) FROM silver.Sellers)
             THEN 'PASS' ELSE 'FAIL' END,
        ABS((COUNT(*) - 1) - (SELECT COUNT(*) FROM silver.Sellers)),
        CONCAT(
            'Silver: ', (SELECT COUNT(*) FROM silver.Sellers),
            ', Gold sellers excluding Unknown Member: ', COUNT(*) - 1
        )
    FROM gold.dim_seller

    UNION ALL

    SELECT
        'Row Count',
        'fact_orders',
        CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM silver.Orders)
             THEN 'PASS' ELSE 'FAIL' END,
        ABS(COUNT(*) - (SELECT COUNT(*) FROM silver.Orders)),
        CONCAT(
            'Silver: ', (SELECT COUNT(*) FROM silver.Orders),
            ', Gold: ', COUNT(*)
        )
    FROM gold.fact_orders

    UNION ALL

    SELECT
        'Row Count',
        'fact_order_items',
        CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM silver.OrderItems)
             THEN 'PASS' ELSE 'FAIL' END,
        ABS(COUNT(*) - (SELECT COUNT(*) FROM silver.OrderItems)),
        CONCAT(
            'Silver: ', (SELECT COUNT(*) FROM silver.OrderItems),
            ', Gold: ', COUNT(*)
        )
    FROM gold.fact_order_items

    UNION ALL

    SELECT
        'Row Count',
        'fact_order_payments',
        CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM silver.OrderPayments)
             THEN 'PASS' ELSE 'FAIL' END,
        ABS(COUNT(*) - (SELECT COUNT(*) FROM silver.OrderPayments)),
        CONCAT(
            'Silver: ', (SELECT COUNT(*) FROM silver.OrderPayments),
            ', Gold: ', COUNT(*)
        )
    FROM gold.fact_order_payments

    UNION ALL

    SELECT
        'Row Count',
        'fact_order_reviews',
        CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM silver.OrderReviews)
             THEN 'PASS' ELSE 'FAIL' END,
        ABS(COUNT(*) - (SELECT COUNT(*) FROM silver.OrderReviews)),
        CONCAT(
            'Silver: ', (SELECT COUNT(*) FROM silver.OrderReviews),
            ', Gold: ', COUNT(*)
        )
    FROM gold.fact_order_reviews


    /* ============================================================================
       2) NULL Checks
       ============================================================================ */

    UNION ALL

    SELECT
        'NULL Check' AS TestName,
        'dim_customer' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        COUNT(*) AS IssueCount,
        'NULL values in required fields' AS Details
    FROM gold.dim_customer
    WHERE CustomerKey IS NULL
       OR CustomerUniqueId IS NULL
       OR CustomerId IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'dim_product',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM gold.dim_product
    WHERE ProductKey IS NULL
       OR ProductId IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'dim_seller',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM gold.dim_seller
    WHERE SellerKey IS NULL
       OR SellerId IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'dim_date',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM gold.dim_date
    WHERE DateKey IS NULL
       OR FullDate IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'fact_orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM gold.fact_orders
    WHERE OrderKey IS NULL
       OR OrderId IS NULL
       OR CustomerKey IS NULL
       OR PurchaseDateKey IS NULL
       OR OrderStatus IS NULL
       OR OrderCount IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'fact_order_items',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM gold.fact_order_items
    WHERE OrderItemKey IS NULL
       OR OrderId IS NULL
       OR OrderItemId IS NULL
       OR CustomerKey IS NULL
       OR ProductKey IS NULL
       OR SellerKey IS NULL
       OR PurchaseDateKey IS NULL
       OR Price IS NULL
       OR FreightValue IS NULL
       OR ItemCount IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'fact_order_payments',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM gold.fact_order_payments
    WHERE OrderPaymentKey IS NULL
       OR OrderId IS NULL
       OR PaymentSequential IS NULL
       OR CustomerKey IS NULL
       OR OrderPurchaseDateKey IS NULL
       OR PaymentType IS NULL
       OR PaymentValue IS NULL
       OR PaymentInstallments IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'fact_order_reviews',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM gold.fact_order_reviews
    WHERE OrderReviewKey IS NULL
       OR OrderId IS NULL
       OR ReviewId IS NULL
       OR CustomerKey IS NULL
       OR ReviewCreationDateKey IS NULL
       OR ReviewScore IS NULL
       OR ReviewCount IS NULL


    /* ============================================================================
       3) Referential Integrity Checks
       ============================================================================ */

    UNION ALL

    SELECT
        'Referential Integrity' AS TestName,
        'fact_orders -> dim_customer' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        COUNT(*) AS IssueCount,
        'Orders referencing non-existent CustomerKey' AS Details
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_customer d ON f.CustomerKey = d.CustomerKey
    WHERE d.CustomerKey IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'fact_orders -> dim_date',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Orders referencing non-existent PurchaseDateKey'
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_date d ON f.PurchaseDateKey = d.DateKey
    WHERE d.DateKey IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'fact_order_items -> dim_customer',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'OrderItems referencing non-existent CustomerKey'
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_customer d ON f.CustomerKey = d.CustomerKey
    WHERE d.CustomerKey IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'fact_order_items -> dim_product',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'OrderItems referencing non-existent ProductKey'
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_product d ON f.ProductKey = d.ProductKey
    WHERE d.ProductKey IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'fact_order_items -> dim_seller',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'OrderItems referencing non-existent SellerKey'
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_seller d ON f.SellerKey = d.SellerKey
    WHERE d.SellerKey IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'fact_order_items -> dim_date',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'OrderItems referencing non-existent PurchaseDateKey'
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_date d ON f.PurchaseDateKey = d.DateKey
    WHERE d.DateKey IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'fact_order_payments -> dim_customer',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Payments referencing non-existent CustomerKey'
    FROM gold.fact_order_payments f
    LEFT JOIN gold.dim_customer d ON f.CustomerKey = d.CustomerKey
    WHERE d.CustomerKey IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'fact_order_payments -> dim_date',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Payments referencing non-existent OrderPurchaseDateKey'
    FROM gold.fact_order_payments f
    LEFT JOIN gold.dim_date d ON f.OrderPurchaseDateKey = d.DateKey
    WHERE d.DateKey IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'fact_order_reviews -> dim_customer',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Reviews referencing non-existent CustomerKey'
    FROM gold.fact_order_reviews f
    LEFT JOIN gold.dim_customer d ON f.CustomerKey = d.CustomerKey
    WHERE d.CustomerKey IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'fact_order_reviews -> dim_date',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Reviews referencing non-existent ReviewCreationDateKey'
    FROM gold.fact_order_reviews f
    LEFT JOIN gold.dim_date d ON f.ReviewCreationDateKey = d.DateKey
    WHERE d.DateKey IS NULL


    /* ============================================================================
       4) Duplicate Key Checks
       ============================================================================ */

    UNION ALL

    SELECT
        'Duplicate PK' AS TestName,
        'dim_customer' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        ISNULL(SUM(dup_count - 1), 0) AS IssueCount,
        'Duplicate CustomerUniqueId values in dim_customer' AS Details
    FROM (
        SELECT CustomerUniqueId, COUNT(*) AS dup_count
        FROM gold.dim_customer
        GROUP BY CustomerUniqueId
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'dim_product',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate ProductId values in dim_product'
    FROM (
        SELECT ProductId, COUNT(*) AS dup_count
        FROM gold.dim_product
        GROUP BY ProductId
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'dim_seller',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate SellerId values in dim_seller'
    FROM (
        SELECT SellerId, COUNT(*) AS dup_count
        FROM gold.dim_seller
        WHERE SellerKey <> -1
        GROUP BY SellerId
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'dim_date',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate FullDate values in dim_date'
    FROM (
        SELECT FullDate, COUNT(*) AS dup_count
        FROM gold.dim_date
        GROUP BY FullDate
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'fact_orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate OrderId values in fact_orders'
    FROM (
        SELECT OrderId, COUNT(*) AS dup_count
        FROM gold.fact_orders
        GROUP BY OrderId
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'fact_order_items',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate Composite Key (OrderId, OrderItemId)'
    FROM (
        SELECT OrderId, OrderItemId, COUNT(*) AS dup_count
        FROM gold.fact_order_items
        GROUP BY OrderId, OrderItemId
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'fact_order_payments',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate Composite Key (OrderId, PaymentSequential)'
    FROM (
        SELECT OrderId, PaymentSequential, COUNT(*) AS dup_count
        FROM gold.fact_order_payments
        GROUP BY OrderId, PaymentSequential
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'fact_order_reviews',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate Composite Key (ReviewId, OrderId)'
    FROM (
        SELECT ReviewId, OrderId, COUNT(*) AS dup_count
        FROM gold.fact_order_reviews
        GROUP BY ReviewId, OrderId
        HAVING COUNT(*) > 1
    ) sub


    /* ============================================================================
       5) Business Logic Checks
       ============================================================================ */

    UNION ALL

    SELECT
        'Business Logic' AS TestName,
        'fact_orders' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        COUNT(*) AS IssueCount,
        'Invalid OrderCount value' AS Details
    FROM gold.fact_orders
    WHERE OrderCount <> 1

    UNION ALL

    SELECT
        'Business Logic',
        'fact_order_items',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid ItemCount value'
    FROM gold.fact_order_items
    WHERE ItemCount <> 1

    UNION ALL

    SELECT
        'Business Logic',
        'fact_order_reviews',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid ReviewCount value'
    FROM gold.fact_order_reviews
    WHERE ReviewCount <> 1

    UNION ALL

    SELECT
        'Business Logic',
        'fact_orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Negative order duration'
    FROM gold.fact_orders
    WHERE ApprovalDays < 0
       OR CarrierDays < 0
       OR DeliveryDays < 0

    UNION ALL

    SELECT
        'Business Logic',
        'fact_orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'IsDelivered inconsistent with DeliveredDateKey'
    FROM gold.fact_orders
    WHERE (IsDelivered = 1 AND DeliveredDateKey IS NULL)
       OR (IsDelivered = 0 AND DeliveredDateKey IS NOT NULL)

    UNION ALL

    SELECT
        'Business Logic',
        'fact_orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'IsLate inconsistent with delivery and estimated dates'
    FROM gold.fact_orders
    WHERE (IsLate = 1 AND (DeliveredDateKey IS NULL OR EstimatedDateKey IS NULL))
       OR (IsLate = 0 AND DeliveredDateKey IS NOT NULL AND EstimatedDateKey IS NOT NULL
           AND DeliveredDateKey > EstimatedDateKey)

    UNION ALL

    SELECT
        'Business Logic',
        'fact_order_items',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Negative Price/FreightValue'
    FROM gold.fact_order_items
    WHERE Price < 0
       OR FreightValue < 0

    UNION ALL

    SELECT
        'Business Logic',
        'fact_order_payments',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid PaymentInstallments/PaymentValue'
    FROM gold.fact_order_payments
    WHERE PaymentInstallments < 1
       OR PaymentValue < 0

    UNION ALL

    SELECT
        'Business Logic',
        'fact_order_reviews',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'ReviewScore outside range 1-5'
    FROM gold.fact_order_reviews
    WHERE ReviewScore < 1
       OR ReviewScore > 5

    UNION ALL

    SELECT
        'Business Logic',
        'dim_seller',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Missing Unknown Member (SellerKey = -1)'
    FROM gold.dim_seller
    WHERE NOT EXISTS (
        SELECT 1
        FROM gold.dim_seller
        WHERE SellerKey = -1
    )


    /* ============================================================================
       6) Date Dimension Checks
       ============================================================================ */

    UNION ALL

    SELECT
        'Date Dimension' AS TestName,
        'dim_date' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        COUNT(*) AS IssueCount,
        'DateKey does not match FullDate' AS Details
    FROM gold.dim_date
    WHERE DateKey <> CONVERT(INT, CONVERT(CHAR(8), FullDate, 112))

    UNION ALL

    SELECT
        'Date Dimension',
        'dim_date',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid weekend indicator'
    FROM gold.dim_date
    WHERE IsWeekend NOT IN (0, 1)

    UNION ALL

    SELECT
        'Date Dimension',
        'dim_date',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid month value'
    FROM gold.dim_date
    WHERE Month NOT BETWEEN 1 AND 12

    UNION ALL

    SELECT
        'Date Dimension',
        'dim_date',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid quarter value'
    FROM gold.dim_date
    WHERE Quarter NOT BETWEEN 1 AND 4;

END;
GO