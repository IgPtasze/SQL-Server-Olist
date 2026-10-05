/*
===============================================================================
Stored Procedure: Validate Silver Layer
===============================================================================
*/
USE OlistDWH;
GO

CREATE OR ALTER PROCEDURE silver.ValidateData AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------------------------
    -- 1) Row Count Checks
    ---------------------------------------------------------------------------

    SELECT
        'Row Count' AS TestName,
        'Customers' AS TableName,
        CASE WHEN b.cnt = s.cnt THEN 'PASS' ELSE 'FAIL' END AS Status,
        ABS(b.cnt - s.cnt) AS IssueCount,
        CONCAT('Bronze: ', b.cnt, ', Silver: ', s.cnt) AS Details
    FROM (SELECT COUNT(*) AS cnt FROM bronze.Customers) b
    CROSS JOIN (SELECT COUNT(*) AS cnt FROM silver.Customers) s

    UNION ALL

    SELECT
        'Row Count', 'Geolocation',
        CASE WHEN b.cnt = s.cnt THEN 'PASS' ELSE 'FAIL' END,
        ABS(b.cnt - s.cnt),
        CONCAT('Bronze: ', b.cnt, ', Silver: ', s.cnt)
    FROM (SELECT COUNT(*) AS cnt FROM bronze.Geolocation) b
    CROSS JOIN (SELECT COUNT(*) AS cnt FROM silver.Geolocation) s

    UNION ALL

    SELECT
        'Row Count', 'OrderItems',
        CASE WHEN b.cnt = s.cnt THEN 'PASS' ELSE 'FAIL' END,
        ABS(b.cnt - s.cnt),
        CONCAT('Bronze: ', b.cnt, ', Silver: ', s.cnt)
    FROM (SELECT COUNT(*) AS cnt FROM bronze.OrderItems) b
    CROSS JOIN (SELECT COUNT(*) AS cnt FROM silver.OrderItems) s

    UNION ALL

    SELECT
        'Row Count', 'OrderPayments',
        CASE WHEN b.cnt = s.cnt THEN 'PASS' ELSE 'FAIL' END,
        ABS(b.cnt - s.cnt),
        CONCAT('Bronze: ', b.cnt, ', Silver: ', s.cnt)
    FROM (SELECT COUNT(*) AS cnt FROM bronze.OrderPayments) b
    CROSS JOIN (SELECT COUNT(*) AS cnt FROM silver.OrderPayments) s

    UNION ALL

    SELECT
        'Row Count', 'OrderReviews',
        CASE WHEN b.cnt = s.cnt THEN 'PASS' ELSE 'FAIL' END,
        ABS(b.cnt - s.cnt),
        CONCAT('Bronze: ', b.cnt, ', Silver: ', s.cnt)
    FROM (SELECT COUNT(*) AS cnt FROM bronze.OrderReviews) b
    CROSS JOIN (SELECT COUNT(*) AS cnt FROM silver.OrderReviews) s

    UNION ALL

    SELECT
        'Row Count', 'Orders',
        CASE WHEN b.cnt = s.cnt THEN 'PASS' ELSE 'FAIL' END,
        ABS(b.cnt - s.cnt),
        CONCAT('Bronze: ', b.cnt, ', Silver: ', s.cnt)
    FROM (SELECT COUNT(*) AS cnt FROM bronze.Orders) b
    CROSS JOIN (SELECT COUNT(*) AS cnt FROM silver.Orders) s

    UNION ALL

    SELECT
        'Row Count', 'ProductCategoryNameTranslation',
        CASE WHEN b.cnt = s.cnt THEN 'PASS' ELSE 'FAIL' END,
        ABS(b.cnt - s.cnt),
        CONCAT('Bronze: ', b.cnt, ', Silver: ', s.cnt)
    FROM (SELECT COUNT(*) AS cnt FROM bronze.ProductCategoryNameTranslation) b
    CROSS JOIN (SELECT COUNT(*) AS cnt FROM silver.ProductCategoryNameTranslation) s

    UNION ALL

    SELECT
        'Row Count', 'Products',
        CASE WHEN b.cnt = s.cnt THEN 'PASS' ELSE 'FAIL' END,
        ABS(b.cnt - s.cnt),
        CONCAT('Bronze: ', b.cnt, ', Silver: ', s.cnt)
    FROM (SELECT COUNT(*) AS cnt FROM bronze.Products) b
    CROSS JOIN (SELECT COUNT(*) AS cnt FROM silver.Products) s

    UNION ALL

    SELECT
        'Row Count', 'Sellers',
        CASE WHEN b.cnt = s.cnt THEN 'PASS' ELSE 'FAIL' END,
        ABS(b.cnt - s.cnt),
        CONCAT('Bronze: ', b.cnt, ', Silver: ', s.cnt)
    FROM (SELECT COUNT(*) AS cnt FROM bronze.Sellers) b
    CROSS JOIN (SELECT COUNT(*) AS cnt FROM silver.Sellers) s


    ---------------------------------------------------------------------------
    -- 2) Conversion Checks
    ---------------------------------------------------------------------------

    UNION ALL

    SELECT
        'Conversion' AS TestName,
        'Geolocation' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        COUNT(*) AS IssueCount,
        'Invalid Lat/Lng values' AS Details
    FROM bronze.Geolocation
    WHERE
        (
            NULLIF(TRIM(Lat), '') IS NOT NULL
            AND TRY_CONVERT(DECIMAL(18,15), NULLIF(TRIM(Lat), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(Lng), '') IS NOT NULL
            AND TRY_CONVERT(DECIMAL(18,15), NULLIF(TRIM(Lng), '')) IS NULL
        )

    UNION ALL

    SELECT
        'Conversion',
        'OrderItems',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid numeric/date values'
    FROM bronze.OrderItems
    WHERE
        (
            NULLIF(TRIM(OrderItemId), '') IS NOT NULL
            AND TRY_CONVERT(INT, NULLIF(TRIM(OrderItemId), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(ShippingLimitDate), '') IS NOT NULL
            AND TRY_CONVERT(DATETIME2, NULLIF(TRIM(ShippingLimitDate), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(Price), '') IS NOT NULL
            AND TRY_CONVERT(DECIMAL(10,2), NULLIF(TRIM(Price), '')) IS NULL
        )
        OR
        (
            NULLIF(
                REPLACE(REPLACE(TRIM(FreightValue), CHAR(13), ''), CHAR(10), ''),
                ''
            ) IS NOT NULL
            AND TRY_CONVERT(
                DECIMAL(10,2),
                NULLIF(
                    REPLACE(REPLACE(TRIM(FreightValue), CHAR(13), ''), CHAR(10), ''),
                    ''
                )
            ) IS NULL
        )

    UNION ALL

    SELECT
        'Conversion',
        'OrderPayments',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid numeric values'
    FROM bronze.OrderPayments
    WHERE
        (
            NULLIF(TRIM(Sequential), '') IS NOT NULL
            AND TRY_CONVERT(INT, NULLIF(TRIM(Sequential), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(Installments), '') IS NOT NULL
            AND TRY_CONVERT(INT, NULLIF(TRIM(Installments), '')) IS NULL
        )
        OR
        (
            NULLIF(
                REPLACE(REPLACE(TRIM(Value), CHAR(13), ''), CHAR(10), ''),
                ''
            ) IS NOT NULL
            AND TRY_CONVERT(
                DECIMAL(10,2),
                NULLIF(
                    REPLACE(REPLACE(TRIM(Value), CHAR(13), ''), CHAR(10), ''),
                    ''
                )
            ) IS NULL
        )

    UNION ALL

    SELECT
        'Conversion',
        'OrderReviews',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid Score/date values'
    FROM bronze.OrderReviews
    WHERE
        (
            NULLIF(TRIM(Score), '') IS NOT NULL
            AND TRY_CONVERT(INT, NULLIF(TRIM(Score), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(CreationDate), '') IS NOT NULL
            AND TRY_CONVERT(DATETIME2, NULLIF(TRIM(CreationDate), '')) IS NULL
        )
        OR
        (
            NULLIF(
                REPLACE(REPLACE(TRIM(AnswerTimestamp), CHAR(13), ''), CHAR(10), ''),
                ''
            ) IS NOT NULL
            AND TRY_CONVERT(
                DATETIME2,
                NULLIF(
                    REPLACE(REPLACE(TRIM(AnswerTimestamp), CHAR(13), ''), CHAR(10), ''),
                    ''
                )
            ) IS NULL
        )

    UNION ALL

    SELECT
        'Conversion',
        'Orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid date values'
    FROM bronze.Orders
    WHERE
        (
            NULLIF(TRIM(PurchaseTimestamp), '') IS NOT NULL
            AND TRY_CONVERT(DATETIME2, NULLIF(TRIM(PurchaseTimestamp), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(ApprovedAt), '') IS NOT NULL
            AND TRY_CONVERT(DATETIME2, NULLIF(TRIM(ApprovedAt), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(DeliveredCarrierDate), '') IS NOT NULL
            AND TRY_CONVERT(DATETIME2, NULLIF(TRIM(DeliveredCarrierDate), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(DeliveredCustomerDate), '') IS NOT NULL
            AND TRY_CONVERT(DATETIME2, NULLIF(TRIM(DeliveredCustomerDate), '')) IS NULL
        )
        OR
        (
            NULLIF(
                REPLACE(REPLACE(TRIM(EstimatedDeliveryDate), CHAR(13), ''), CHAR(10), ''),
                ''
            ) IS NOT NULL
            AND TRY_CONVERT(
                DATETIME2,
                NULLIF(
                    REPLACE(REPLACE(TRIM(EstimatedDeliveryDate), CHAR(13), ''), CHAR(10), ''),
                    ''
                )
            ) IS NULL
        )

    UNION ALL

    SELECT
        'Conversion',
        'Products',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid numeric values'
    FROM bronze.Products
    WHERE
        (
            NULLIF(TRIM(NameLenght), '') IS NOT NULL
            AND TRY_CONVERT(INT, NULLIF(TRIM(NameLenght), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(DescriptionLength), '') IS NOT NULL
            AND TRY_CONVERT(INT, NULLIF(TRIM(DescriptionLength), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(PhotosQty), '') IS NOT NULL
            AND TRY_CONVERT(INT, NULLIF(TRIM(PhotosQty), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(WeightG), '') IS NOT NULL
            AND TRY_CONVERT(INT, NULLIF(TRIM(WeightG), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(LengthCm), '') IS NOT NULL
            AND TRY_CONVERT(INT, NULLIF(TRIM(LengthCm), '')) IS NULL
        )
        OR
        (
            NULLIF(TRIM(HeightCm), '') IS NOT NULL
            AND TRY_CONVERT(INT, NULLIF(TRIM(HeightCm), '')) IS NULL
        )
        OR
        (
            NULLIF(
                REPLACE(REPLACE(TRIM(WidthCm), CHAR(13), ''), CHAR(10), ''),
                ''
            ) IS NOT NULL
            AND TRY_CONVERT(
                INT,
                NULLIF(
                    REPLACE(REPLACE(TRIM(WidthCm), CHAR(13), ''), CHAR(10), ''),
                    ''
                )
            ) IS NULL
        )


    ---------------------------------------------------------------------------
    -- 3) NULL Check
    ---------------------------------------------------------------------------

    UNION ALL

    SELECT
        'NULL Check' AS TestName,
        'Customers' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        COUNT(*) AS IssueCount,
        'NULL values in required fields' AS Details
    FROM silver.Customers
    WHERE Id IS NULL
       OR UniqueId IS NULL
       OR ZipCodePrefix IS NULL
       OR City IS NULL
       OR State IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'Geolocation',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM silver.Geolocation
    WHERE ZipCodePrefix IS NULL
       OR Lat IS NULL
       OR Lng IS NULL
       OR City IS NULL
       OR State IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'OrderItems',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM silver.OrderItems
    WHERE OrderId IS NULL
       OR OrderItemId IS NULL
       OR ProductId IS NULL
       OR SellerId IS NULL
       OR Price IS NULL
       OR FreightValue IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'OrderPayments',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM silver.OrderPayments
    WHERE OrderId IS NULL
       OR Sequential IS NULL
       OR Type IS NULL
       OR Value IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'OrderReviews',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM silver.OrderReviews
    WHERE ReviewId IS NULL
       OR OrderId IS NULL
       OR Score IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'Orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM silver.Orders
    WHERE Id IS NULL
       OR CustomerId IS NULL
       OR Status IS NULL
       OR PurchaseTimestamp IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'Products',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM silver.Products
    WHERE Id IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'Sellers',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM silver.Sellers
    WHERE Id IS NULL
       OR ZipCodePrefix IS NULL
       OR City IS NULL
       OR State IS NULL

    UNION ALL

    SELECT
        'NULL Check',
        'ProductCategoryNameTranslation',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'NULL values in required fields'
    FROM silver.ProductCategoryNameTranslation
    WHERE CategoryName IS NULL
       OR CategoryNameEnglish IS NULL


    ---------------------------------------------------------------------------
    -- 4) Value Range Checks
    ---------------------------------------------------------------------------

    UNION ALL

    SELECT
        'Value Range' AS TestName,
        'OrderItems' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        COUNT(*) AS IssueCount,
        'Negative Price/FreightValue' AS Details
    FROM silver.OrderItems
    WHERE Price < 0
       OR FreightValue < 0

    UNION ALL

    SELECT
        'Value Range',
        'OrderPayments',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid Installments/Value'
    FROM silver.OrderPayments
    WHERE Installments < 1
       OR Value < 0

    UNION ALL

    SELECT
        'Value Range',
        'OrderReviews',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Score outside range 1-5'
    FROM silver.OrderReviews
    WHERE Score < 1
       OR Score > 5

    UNION ALL

    SELECT
        'Value Range',
        'Products',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Invalid product dimensions'
    FROM silver.Products
    WHERE WeightG < 0
       OR LengthCm < 0
       OR HeightCm < 0
       OR WidthCm < 0


    ---------------------------------------------------------------------------
    -- 5) Date Consistency Checks
    ---------------------------------------------------------------------------

    UNION ALL

    SELECT
        'Date Consistency' AS TestName,
        'Orders' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        COUNT(*) AS IssueCount,
        'Delivered date before purchase date' AS Details
    FROM silver.Orders
    WHERE DeliveredCarrierDate < PurchaseTimestamp
       OR DeliveredCustomerDate < PurchaseTimestamp


    ---------------------------------------------------------------------------
    -- 6) Referential Integrity Checks (Orphan Records)
    ---------------------------------------------------------------------------

    UNION ALL

    SELECT
        'Referential Integrity' AS TestName,
        'Orders -> Customers' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        COUNT(*) AS IssueCount,
        'Orders referencing non-existent CustomerId' AS Details
    FROM silver.Orders o
    LEFT JOIN silver.Customers c ON o.CustomerId = c.Id
    WHERE o.CustomerId IS NOT NULL AND c.Id IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'OrderItems -> Orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'OrderItems referencing non-existent OrderId'
    FROM silver.OrderItems oi
    LEFT JOIN silver.Orders o ON oi.OrderId = o.Id
    WHERE oi.OrderId IS NOT NULL AND o.Id IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'OrderItems -> Products',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'OrderItems referencing non-existent ProductId'
    FROM silver.OrderItems oi
    LEFT JOIN silver.Products p ON oi.ProductId = p.Id
    WHERE oi.ProductId IS NOT NULL AND p.Id IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'OrderItems -> Sellers',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'OrderItems referencing non-existent SellerId'
    FROM silver.OrderItems oi
    LEFT JOIN silver.Sellers s ON oi.SellerId = s.Id
    WHERE oi.SellerId IS NOT NULL AND s.Id IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'OrderPayments -> Orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'OrderPayments referencing non-existent OrderId'
    FROM silver.OrderPayments op
    LEFT JOIN silver.Orders o ON op.OrderId = o.Id
    WHERE op.OrderId IS NOT NULL AND o.Id IS NULL

    UNION ALL

    SELECT
        'Referential Integrity',
        'OrderReviews -> Orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'OrderReviews referencing non-existent OrderId'
    FROM silver.OrderReviews ORv
    LEFT JOIN silver.Orders o ON ORv.OrderId = o.Id
    WHERE ORv.OrderId IS NOT NULL AND o.Id IS NULL


    ---------------------------------------------------------------------------
    -- 7) Duplicate Primary Key Checks
    ---------------------------------------------------------------------------

    UNION ALL

    SELECT
        'Duplicate PK' AS TestName,
        'Customers' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        ISNULL(SUM(dup_count - 1), 0) AS IssueCount,
        'Duplicate Id values in Customers' AS Details
    FROM (
        SELECT Id, COUNT(*) AS dup_count 
        FROM silver.Customers
        GROUP BY Id 
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'Orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate Id values in Orders'
    FROM (
        SELECT Id, COUNT(*) AS dup_count 
        FROM silver.Orders
        GROUP BY Id 
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'Products',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate Id values in Products'
    FROM (
        SELECT Id, COUNT(*) AS dup_count 
        FROM silver.Products
        GROUP BY Id 
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'Sellers',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate Id values in Sellers'
    FROM (
        SELECT Id, COUNT(*) AS dup_count 
        FROM silver.Sellers 
        GROUP BY Id 
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'OrderItems',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate Composite PK (OrderId, OrderItemId)'
    FROM (
        SELECT OrderId, OrderItemId, COUNT(*) AS dup_count 
        FROM silver.OrderItems 
        GROUP BY OrderId, OrderItemId 
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK',
        'OrderPayments',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(SUM(dup_count - 1), 0),
        'Duplicate Composite PK (OrderId, Sequential)'
    FROM (
        SELECT OrderId, Sequential, COUNT(*) AS dup_count 
        FROM silver.OrderPayments 
        GROUP BY OrderId, Sequential 
        HAVING COUNT(*) > 1
    ) sub

    UNION ALL

    SELECT
        'Duplicate PK' AS TestName,
        'OrderReviews' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        ISNULL(SUM(dup_count - 1), 0) AS IssueCount,
        'Duplicate Composite PK (ReviewId, OrderId)' AS Details
    FROM (
        SELECT ReviewId, OrderId, COUNT(*) AS dup_count
        FROM silver.OrderReviews
        GROUP BY ReviewId, OrderId
        HAVING COUNT(*) > 1
    ) sub


    ---------------------------------------------------------------------------
    -- 8) LoadTimestamp Checks
    ---------------------------------------------------------------------------

    UNION ALL

    SELECT
        'LoadTimestamp' AS TestName,
        'Customers' AS TableName,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status,
        COUNT(*) AS IssueCount,
        'Missing LoadTimestamp' AS Details
    FROM silver.Customers
    WHERE LoadTimestamp IS NULL

    UNION ALL

    SELECT
        'LoadTimestamp',
        'Geolocation',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Missing LoadTimestamp'
    FROM silver.Geolocation
    WHERE LoadTimestamp IS NULL

    UNION ALL

    SELECT
        'LoadTimestamp',
        'OrderItems',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Missing LoadTimestamp'
    FROM silver.OrderItems
    WHERE LoadTimestamp IS NULL

    UNION ALL

    SELECT
        'LoadTimestamp',
        'OrderPayments',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Missing LoadTimestamp'
    FROM silver.OrderPayments
    WHERE LoadTimestamp IS NULL

    UNION ALL

    SELECT
        'LoadTimestamp',
        'OrderReviews',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Missing LoadTimestamp'
    FROM silver.OrderReviews
    WHERE LoadTimestamp IS NULL

    UNION ALL

    SELECT
        'LoadTimestamp',
        'Orders',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Missing LoadTimestamp'
    FROM silver.Orders
    WHERE LoadTimestamp IS NULL

    UNION ALL

    SELECT
        'LoadTimestamp',
        'ProductCategoryNameTranslation',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Missing LoadTimestamp'
    FROM silver.ProductCategoryNameTranslation
    WHERE LoadTimestamp IS NULL

    UNION ALL

    SELECT
        'LoadTimestamp',
        'Products',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Missing LoadTimestamp'
    FROM silver.Products
    WHERE LoadTimestamp IS NULL

    UNION ALL

    SELECT
        'LoadTimestamp',
        'Sellers',
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*),
        'Missing LoadTimestamp'
    FROM silver.Sellers
    WHERE LoadTimestamp IS NULL;

END;
GO