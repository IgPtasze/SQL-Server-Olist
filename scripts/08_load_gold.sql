/*
===============================================================================
Stored Procedure: Load Data Into Gold Layer
===============================================================================
Loads data from the Silver layer into the Gold dimensional model.

The Gold layer follows a Kimball-style dimensional model consisting of
dimensions and fact tables.

Dimensions:
- dim_customer
- dim_product
- dim_seller
- dim_date

Facts:
- fact_orders
- fact_order_items
- fact_order_payments
- fact_order_reviews

The procedure performs a full reload of the Gold layer.

Dimensions are loaded before fact tables because fact tables contain foreign
keys referencing the dimensions.

Seller records that cannot be matched to dim_seller are assigned to the
Unknown Member (SellerKey = -1).
===============================================================================
*/

USE OlistDWH;
GO

CREATE OR ALTER PROCEDURE gold.LoadData AS
BEGIN
    DECLARE @StartTime DATETIME2, @EndTime DATETIME2, @BatchStartTime DATETIME2;

    BEGIN TRY
        SET @BatchStartTime = SYSDATETIME();

        /* ============================================================================
           Load Gold Layer
        ============================================================================ */

        BEGIN TRANSACTION;

        PRINT 'Loading Data Into Gold Layer:';


        /* ----------------------------------------------------------------------------
           Clear Fact Tables
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Truncating Table: gold.fact_order_reviews';
        TRUNCATE TABLE gold.fact_order_reviews;

        PRINT '    Truncating Table: gold.fact_order_payments';
        TRUNCATE TABLE gold.fact_order_payments;

        PRINT '    Truncating Table: gold.fact_order_items';
        TRUNCATE TABLE gold.fact_order_items;

        PRINT '    Truncating Table: gold.fact_orders';
        TRUNCATE TABLE gold.fact_orders;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Clear Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Clear Dimension Tables
        ---------------------------------------------------------------------------- */

        /*
        Dimension tables are referenced by foreign keys from fact tables.
        DELETE is therefore used instead of TRUNCATE.
        */

        SET @StartTime = SYSDATETIME();

        PRINT '    Deleting Data From: gold.dim_date';
        DELETE FROM gold.dim_date;

        PRINT '    Deleting Data From: gold.dim_seller';
        DELETE FROM gold.dim_seller;

        PRINT '    Deleting Data From: gold.dim_product';
        DELETE FROM gold.dim_product;

        PRINT '    Deleting Data From: gold.dim_customer';
        DELETE FROM gold.dim_customer;

        -- Reset identity values for full reload.
        DBCC CHECKIDENT ('gold.dim_seller', RESEED, 0);
        DBCC CHECKIDENT ('gold.dim_product', RESEED, 0);
        DBCC CHECKIDENT ('gold.dim_customer', RESEED, 0);

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Clear Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Customer Dimension
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Inserting Data Into: gold.dim_customer';

        /*
        Customer dimension grain is CustomerUniqueId.

        A CustomerUniqueId can be associated with multiple CustomerId values
        in the source data. One representative record is therefore selected
        for each CustomerUniqueId.
        */

        ;WITH CustomerSource AS
        (
            SELECT
                c.CustomerUniqueId,
                c.CustomerId,
                c.CustomerZipCodePrefix,
                c.CustomerCity,
                c.CustomerState,
                ROW_NUMBER() OVER (
                    PARTITION BY c.CustomerUniqueId
                    ORDER BY c.CustomerId
                ) AS RowNumber
            FROM silver.Customers c
            WHERE c.CustomerUniqueId IS NOT NULL
        )
        INSERT INTO gold.dim_customer (
            CustomerUniqueId,
            CustomerId,
            ZipCodePrefix,
            City,
            State
        )
        SELECT
            CustomerUniqueId,
            CustomerId,
            CustomerZipCodePrefix,
            CustomerCity,
            CustomerState
        FROM CustomerSource
        WHERE RowNumber = 1;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Product Dimension
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Inserting Data Into: gold.dim_product';

        INSERT INTO gold.dim_product (
            ProductId,
            CategoryName,
            CategoryNameEnglish,
            PhotosQty,
            WeightG,
            LengthCM,
            HeightCM,
            WidthCM
        )
        SELECT
            p.ProductId,
            p.ProductCategoryName,
            t.ProductCategoryNameEnglish,
            p.ProductPhotosQty,
            p.ProductWeightG,
            p.ProductLengthCm,
            p.ProductHeightCm,
            p.ProductWidthCm
        FROM silver.Products p
        LEFT JOIN silver.ProductCategoryNameTranslation t
            ON p.ProductCategoryName = t.ProductCategoryName;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Seller Dimension
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Inserting Data Into: gold.dim_seller';

        /*
        SellerKey = -1 is reserved for the Unknown Member.
        It is used when an OrderItem references a SellerId that does not exist
        in the Silver Sellers table.
        */

        SET IDENTITY_INSERT gold.dim_seller ON;

        INSERT INTO gold.dim_seller (
            SellerKey,
            SellerId,
            ZipCodePrefix,
            City,
            State
        )
        VALUES (
            -1,
            'UNKNOWN',
            NULL,
            'Unknown',
            NULL
        );

        SET IDENTITY_INSERT gold.dim_seller OFF;

        INSERT INTO gold.dim_seller (
            SellerId,
            ZipCodePrefix,
            City,
            State
        )
        SELECT
            SellerId,
            SellerZipCodePrefix,
            SellerCity,
            SellerState
        FROM silver.Sellers;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Date Dimension
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Inserting Data Into: gold.dim_date';

        DECLARE @MinDate DATE;
        DECLARE @MaxDate DATE;

        SELECT
            @MinDate = MIN(SourceDate),
            @MaxDate = MAX(SourceDate)
        FROM
        (
            SELECT CAST(OrderPurchaseTimestamp AS DATE) AS SourceDate
            FROM silver.Orders
            WHERE OrderPurchaseTimestamp IS NOT NULL

            UNION ALL

            SELECT CAST(OrderApprovedAt AS DATE)
            FROM silver.Orders
            WHERE OrderApprovedAt IS NOT NULL

            UNION ALL

            SELECT CAST(OrderDeliveredCarrierDate AS DATE)
            FROM silver.Orders
            WHERE OrderDeliveredCarrierDate IS NOT NULL

            UNION ALL

            SELECT CAST(OrderDeliveredCustomerDate AS DATE)
            FROM silver.Orders
            WHERE OrderDeliveredCustomerDate IS NOT NULL

            UNION ALL

            SELECT CAST(OrderEstimatedDeliveryDate AS DATE)
            FROM silver.Orders
            WHERE OrderEstimatedDeliveryDate IS NOT NULL

            UNION ALL

            SELECT CAST(ReviewCreationDate AS DATE)
            FROM silver.OrderReviews
            WHERE ReviewCreationDate IS NOT NULL

            UNION ALL

            SELECT CAST(ReviewAnswerTimestamp AS DATE)
            FROM silver.OrderReviews
            WHERE ReviewAnswerTimestamp IS NOT NULL
        ) Dates;


        ;WITH DateRange AS
        (
            SELECT @MinDate AS FullDate
            WHERE @MinDate IS NOT NULL

            UNION ALL

            SELECT DATEADD(DAY, 1, FullDate)
            FROM DateRange
            WHERE FullDate IS NOT NULL
              AND FullDate < @MaxDate
        )
        INSERT INTO gold.dim_date (
            DateKey,
            FullDate,
            Year,
            Quarter,
            Month,
            MonthName,
            Week,
            DayOfMonth,
            DayOfWeek,
            DayName,
            IsWeekend
        )
        SELECT
            CONVERT(INT, CONVERT(CHAR(8), FullDate, 112)) AS DateKey,
            FullDate,
            DATEPART(YEAR, FullDate) AS Year,
            DATEPART(QUARTER, FullDate) AS Quarter,
            DATEPART(MONTH, FullDate) AS Month,
            DATENAME(MONTH, FullDate) AS MonthName,
            DATEPART(WEEK, FullDate) AS Week,
            DATEPART(DAY, FullDate) AS DayOfMonth,
            DATEPART(WEEKDAY, FullDate) AS DayOfWeek,
            DATENAME(WEEKDAY, FullDate) AS DayName,
            CASE
                WHEN DATEPART(WEEKDAY, FullDate) IN (1, 7)
                    THEN 1
                ELSE 0
            END AS IsWeekend
        FROM DateRange
        OPTION (MAXRECURSION 0);

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Orders Fact
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Inserting Data Into: gold.fact_orders';

        INSERT INTO gold.fact_orders (
            OrderId,
            CustomerKey,
            PurchaseDateKey,
            ApprovedDateKey,
            CarrierDateKey,
            DeliveredDateKey,
            EstimatedDateKey,
            OrderStatus,
            ApprovalDays,
            CarrierDays,
            DeliveryDays,
            IsDelivered,
            IsLate,
            OrderCount
        )
        SELECT
            o.OrderId,
            dc.CustomerKey,

            CONVERT(INT, CONVERT(CHAR(8),
                CAST(o.OrderPurchaseTimestamp AS DATE), 112)),

            CASE
                WHEN o.OrderApprovedAt IS NOT NULL
                THEN CONVERT(INT, CONVERT(CHAR(8),
                    CAST(o.OrderApprovedAt AS DATE), 112))
                ELSE NULL
            END,

            CASE
                WHEN o.OrderDeliveredCarrierDate IS NOT NULL
                THEN CONVERT(INT, CONVERT(CHAR(8),
                    CAST(o.OrderDeliveredCarrierDate AS DATE), 112))
                ELSE NULL
            END,

            CASE
                WHEN o.OrderDeliveredCustomerDate IS NOT NULL
                THEN CONVERT(INT, CONVERT(CHAR(8),
                    CAST(o.OrderDeliveredCustomerDate AS DATE), 112))
                ELSE NULL
            END,

            CONVERT(INT, CONVERT(CHAR(8),
                CAST(o.OrderEstimatedDeliveryDate AS DATE), 112)),

            o.OrderStatus,

            CASE
                WHEN o.OrderApprovedAt IS NOT NULL
                THEN DATEDIFF(
                    DAY,
                    o.OrderPurchaseTimestamp,
                    o.OrderApprovedAt
                )
                ELSE NULL
            END,

            CASE
                WHEN o.OrderDeliveredCarrierDate IS NOT NULL
                THEN DATEDIFF(
                    DAY,
                    o.OrderPurchaseTimestamp,
                    o.OrderDeliveredCarrierDate
                )
                ELSE NULL
            END,

            CASE
                WHEN o.OrderDeliveredCustomerDate IS NOT NULL
                THEN DATEDIFF(
                    DAY,
                    o.OrderPurchaseTimestamp,
                    o.OrderDeliveredCustomerDate
                )
                ELSE NULL
            END,

            CASE
                WHEN o.OrderDeliveredCustomerDate IS NOT NULL
                    THEN 1
                ELSE 0
            END,

            CASE
                WHEN o.OrderDeliveredCustomerDate IS NOT NULL
                     AND o.OrderEstimatedDeliveryDate IS NOT NULL
                     AND o.OrderDeliveredCustomerDate >
                         o.OrderEstimatedDeliveryDate
                    THEN 1
                WHEN o.OrderDeliveredCustomerDate IS NOT NULL
                    THEN 0
                ELSE NULL
            END,

            1
        FROM silver.Orders o
        INNER JOIN silver.Customers c
            ON o.CustomerId = c.CustomerId
        INNER JOIN gold.dim_customer dc
            ON c.CustomerUniqueId = dc.CustomerUniqueId;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Order Items Fact
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Inserting Data Into: gold.fact_order_items';

        INSERT INTO gold.fact_order_items (
            OrderId,
            OrderItemId,
            CustomerKey,
            ProductKey,
            SellerKey,
            PurchaseDateKey,
            Price,
            FreightValue,
            ItemCount
        )
        SELECT
            oi.OrderId,
            oi.OrderItemId,
            dc.CustomerKey,
            dp.ProductKey,
            ISNULL(ds.SellerKey, -1),

            CONVERT(INT, CONVERT(CHAR(8),
                CAST(o.OrderPurchaseTimestamp AS DATE), 112)),

            oi.Price,
            oi.FreightValue,
            1
        FROM silver.OrderItems oi
        INNER JOIN silver.Orders o
            ON oi.OrderId = o.OrderId
        INNER JOIN silver.Customers c
            ON o.CustomerId = c.CustomerId
        INNER JOIN gold.dim_customer dc
            ON c.CustomerUniqueId = dc.CustomerUniqueId
        INNER JOIN gold.dim_product dp
            ON oi.ProductId = dp.ProductId
        LEFT JOIN gold.dim_seller ds
            ON oi.SellerId = ds.SellerId;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Order Payments Fact
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Inserting Data Into: gold.fact_order_payments';

        INSERT INTO gold.fact_order_payments (
            OrderId,
            PaymentSequential,
            CustomerKey,
            OrderPurchaseDateKey,
            PaymentType,
            PaymentValue,
            PaymentInstallments
        )
        SELECT
            op.OrderId,
            op.PaymentSequential,
            dc.CustomerKey,

            CONVERT(INT, CONVERT(CHAR(8),
                CAST(o.OrderPurchaseTimestamp AS DATE), 112)),

            op.PaymentType,
            op.PaymentValue,
            op.PaymentInstallments
        FROM silver.OrderPayments op
        INNER JOIN silver.Orders o
            ON op.OrderId = o.OrderId
        INNER JOIN silver.Customers c
            ON o.CustomerId = c.CustomerId
        INNER JOIN gold.dim_customer dc
            ON c.CustomerUniqueId = dc.CustomerUniqueId;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Order Reviews Fact
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Inserting Data Into: gold.fact_order_reviews';

        INSERT INTO gold.fact_order_reviews (
            OrderId,
            ReviewId,
            CustomerKey,
            ReviewCreationDateKey,
            ReviewAnswerDateKey,
            ReviewScore,
            ReviewCount
        )
        SELECT
            r.OrderId,
            r.ReviewId,
            dc.CustomerKey,

            CONVERT(INT, CONVERT(CHAR(8),
                CAST(r.ReviewCreationDate AS DATE), 112)),

            CASE
                WHEN r.ReviewAnswerTimestamp IS NOT NULL
                THEN CONVERT(INT, CONVERT(CHAR(8),
                    CAST(r.ReviewAnswerTimestamp AS DATE), 112))
                ELSE NULL
            END,

            r.ReviewScore,
            1
        FROM silver.OrderReviews r
        INNER JOIN silver.Orders o
            ON r.OrderId = o.OrderId
        INNER JOIN silver.Customers c
            ON o.CustomerId = c.CustomerId
        INNER JOIN gold.dim_customer dc
            ON c.CustomerUniqueId = dc.CustomerUniqueId;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ============================================================================
           Commit Transaction
        ============================================================================ */

        COMMIT TRANSACTION;

        SET @EndTime = SYSDATETIME();

        PRINT 'Gold Layer Load Duration: ' + CAST(DATEDIFF(second, @BatchStartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


    END TRY


    /* ============================================================================
       Error Handling
    ============================================================================ */

    BEGIN CATCH

        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;

        PRINT '!!! ERROR OCCURRED DURING LOADING DATA !!!';
        PRINT CAST(ERROR_NUMBER() AS NVARCHAR) + ' - ' + ERROR_MESSAGE();

        THROW;

    END CATCH
END;
GO