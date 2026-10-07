/*
===============================================================================
Stored Procedure: Load Data Into Silver Layer (Cleansed & Conformed)
===============================================================================
Loads and transforms data from the Bronze layer into the Silver layer.

The Silver layer contains cleaned and standardized data, including data type
conversion, whitespace and line break removal, NULL handling and selected
data quality corrections.

LoadTimestamp records the time when each row is loaded into the Silver layer.
===============================================================================
*/

USE OlistDWH;
GO

CREATE OR ALTER PROCEDURE silver.LoadData AS
BEGIN
    DECLARE @StartTime DATETIME2, @EndTime DATETIME2, @BatchStartTime DATETIME2;

    BEGIN TRY
        SET @BatchStartTime = SYSDATETIME();

        /* ============================================================================
           Load Silver Layer
        ============================================================================ */

        BEGIN TRANSACTION;

        PRINT 'Loading Data Into Silver Layer:';


        /* ----------------------------------------------------------------------------
           Customers
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Truncating Table: silver.Customers';
        TRUNCATE TABLE silver.Customers;
    
        PRINT '    Inserting Data Into: silver.Customers';
        INSERT INTO silver.Customers (
            CustomerId,
            CustomerUniqueId,
            CustomerZipCodePrefix,
            CustomerCity,
            CustomerState,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(CustomerId), ''),
            NULLIF(TRIM(CustomerUniqueId), ''),
            NULLIF(TRIM(CustomerZipCodePrefix), ''),
            NULLIF(TRIM(CustomerCity), ''),
            NULLIF(REPLACE(REPLACE(TRIM(CustomerState), CHAR(13), ''), CHAR(10), ''), ''),
            SYSDATETIME()
        FROM bronze.Customers;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                    ';


        /* ----------------------------------------------------------------------------
           Geolocation
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Truncating Table: silver.Geolocation';
        TRUNCATE TABLE silver.Geolocation;

        PRINT '    Inserting Data Into: silver.Geolocation';
        INSERT INTO silver.Geolocation (
            GeolocationZipCodePrefix,
            GeolocationLat,
            GeolocationLng,
            GeolocationCity,
            GeolocationState,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(GeolocationZipCodePrefix), ''),
            TRY_CONVERT(DECIMAL(18,15), NULLIF(TRIM(GeolocationLat), '')),
            TRY_CONVERT(DECIMAL(18,15), NULLIF(TRIM(GeolocationLng), '')),
            NULLIF(TRIM(GeolocationCity), ''),
            NULLIF(REPLACE(REPLACE(TRIM(GeolocationState), CHAR(13), ''), CHAR(10), ''), ''),
            SYSDATETIME()
        FROM bronze.Geolocation;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Order Items
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Truncating Table: silver.OrderItems';
        TRUNCATE TABLE silver.OrderItems;

        PRINT '    Inserting Data Into: silver.OrderItems';
        INSERT INTO silver.OrderItems (
            OrderId,
            OrderItemId,
            ProductId,
            SellerId,
            ShippingLimitDate,
            Price,
            FreightValue,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(OrderId), ''),
            TRY_CONVERT(INT, NULLIF(TRIM(OrderItemId), '')),
            NULLIF(TRIM(ProductId), ''),
            /*
            DATA QUALITY NOTE:
            Contains 3 orphan SellerIds missing from bronze.Sellers
            (olist_sellers_dataset).

            Retained in Silver to preserve order metrics; handled via an
            'Unknown Member' (-1) in the Gold dimensional model.
            */
            NULLIF(TRIM(SellerId), ''),
            TRY_CONVERT(DATETIME2, NULLIF(TRIM(ShippingLimitDate), '')),
            TRY_CONVERT(DECIMAL(10,2), NULLIF(TRIM(Price), '')),
            TRY_CONVERT(
                DECIMAL(10,2),
                NULLIF(REPLACE(REPLACE(TRIM(FreightValue), CHAR(13), ''), CHAR(10), ''), '')
            ),
            SYSDATETIME()
        FROM bronze.OrderItems;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Order Payments
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Truncating Table: silver.OrderPayments';
        TRUNCATE TABLE silver.OrderPayments;

        PRINT '    Inserting Data Into: silver.OrderPayments';
        INSERT INTO silver.OrderPayments (
            OrderId,
            PaymentSequential,
            PaymentType,
            PaymentInstallments,
            PaymentValue,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(OrderId), ''),
            TRY_CONVERT(INT, NULLIF(TRIM(PaymentSequential), '')),
            NULLIF(TRIM(PaymentType), ''),
            /*
            DATA QUALITY FIX:
            Handle 2 records with 0 installments.

            Map 0 installments to 1 (single-lump payment) to prevent
            division-by-zero errors in downstream financial metrics.
            */
            CASE 
                WHEN TRY_CONVERT(INT, NULLIF(TRIM(PaymentInstallments), '')) < 1 THEN 1 
                ELSE TRY_CONVERT(INT, NULLIF(TRIM(PaymentInstallments), '')) 
            END,
            TRY_CONVERT(
                DECIMAL(10,2),
                NULLIF(REPLACE(REPLACE(TRIM(PaymentValue), CHAR(13), ''), CHAR(10), ''), '')
            ),
            SYSDATETIME()
        FROM bronze.OrderPayments;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Order Reviews
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Truncating Table: silver.OrderReviews';
        TRUNCATE TABLE silver.OrderReviews;

        PRINT '    Inserting Data Into: silver.OrderReviews';
        INSERT INTO silver.OrderReviews (
            ReviewId,
            OrderId,
            ReviewScore,
            ReviewCommentTitle,
            ReviewCommentMessage,
            ReviewCreationDate,
            ReviewAnswerTimestamp,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(ReviewId), ''),
            NULLIF(TRIM(OrderId), ''),
            TRY_CONVERT(INT, NULLIF(TRIM(ReviewScore), '')),
            NULLIF(TRIM(ReviewCommentTitle), ''),
            NULLIF(TRIM(ReviewCommentMessage), ''),
            TRY_CONVERT(DATETIME2, NULLIF(TRIM(ReviewCreationDate), '')),
            TRY_CONVERT(
                DATETIME2,
                NULLIF(REPLACE(REPLACE(TRIM(ReviewAnswerTimestamp), CHAR(13), ''), CHAR(10), ''), '')
            ),
            SYSDATETIME()
        FROM bronze.OrderReviews;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Orders
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Truncating Table: silver.Orders';
        TRUNCATE TABLE silver.Orders;

        PRINT '    Inserting Data Into: silver.Orders';
        INSERT INTO silver.Orders (
            OrderId,
            CustomerId,
            OrderStatus,
            OrderPurchaseTimestamp,
            OrderApprovedAt,
            OrderDeliveredCarrierDate,
            OrderDeliveredCustomerDate,
            OrderEstimatedDeliveryDate,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(OrderId), ''),
            NULLIF(TRIM(CustomerId), ''),
            NULLIF(TRIM(OrderStatus), ''),
            TRY_CONVERT(DATETIME2, NULLIF(TRIM(OrderPurchaseTimestamp), '')),
            TRY_CONVERT(DATETIME2, NULLIF(TRIM(OrderApprovedAt), '')),
            /*
            DATA QUALITY FIX:
            Handle 166 records where carrier pickup predated purchase timestamp.

            Set invalid chronological carrier dates to NULL to preserve order
            entity integrity without distorting logistics KPIs.
            */
            CASE 
                WHEN TRY_CONVERT(DATETIME2, NULLIF(TRIM(OrderDeliveredCarrierDate), '')) 
                     < TRY_CONVERT(DATETIME2, NULLIF(TRIM(OrderPurchaseTimestamp), '')) 
                THEN NULL 
                ELSE TRY_CONVERT(DATETIME2, NULLIF(TRIM(OrderDeliveredCarrierDate), '')) 
            END,
            TRY_CONVERT(DATETIME2, NULLIF(TRIM(OrderDeliveredCustomerDate), '')),
            TRY_CONVERT(
                DATETIME2,
                NULLIF(REPLACE(REPLACE(TRIM(OrderEstimatedDeliveryDate), CHAR(13), ''), CHAR(10), ''), '')
            ),
            SYSDATETIME()
        FROM bronze.Orders;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Products
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Truncating Table: silver.Products';
        TRUNCATE TABLE silver.Products;

        PRINT '    Inserting Data Into: silver.Products';
        INSERT INTO silver.Products (
            ProductId,
            ProductCategoryName,
            ProductNameLength,
            ProductDescriptionLength,
            ProductPhotosQty,
            ProductWeightG,
            ProductLengthCm,
            ProductHeightCm,
            ProductWidthCm,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(ProductId), ''),
            NULLIF(TRIM(ProductCategoryName), ''),
            TRY_CONVERT(INT, NULLIF(TRIM(ProductNameLenght), '')),
            TRY_CONVERT(INT, NULLIF(TRIM(ProductDescriptionLenght), '')),
            TRY_CONVERT(INT, NULLIF(TRIM(ProductPhotosQty), '')),
            TRY_CONVERT(INT, NULLIF(TRIM(ProductWeightG), '')),
            TRY_CONVERT(INT, NULLIF(TRIM(ProductLengthCm), '')),
            TRY_CONVERT(INT, NULLIF(TRIM(ProductHeightCm), '')),
            TRY_CONVERT(
                INT,
                NULLIF(REPLACE(REPLACE(TRIM(ProductWidthCm), CHAR(13), ''), CHAR(10), ''), '')
            ),
            SYSDATETIME()
        FROM bronze.Products;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Sellers
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Truncating Table: silver.Sellers';
        TRUNCATE TABLE silver.Sellers;

        PRINT '    Inserting Data Into: silver.Sellers';
        INSERT INTO silver.Sellers (
            SellerId,
            SellerZipCodePrefix,
            SellerCity,
            SellerState,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(SellerId), ''),
            NULLIF(TRIM(SellerZipCodePrefix), ''),
            NULLIF(TRIM(SellerCity), ''),
            NULLIF(REPLACE(REPLACE(TRIM(SellerState), CHAR(13), ''), CHAR(10), ''), ''),
            SYSDATETIME()
        FROM bronze.Sellers;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ----------------------------------------------------------------------------
           Product Category Name Translation
        ---------------------------------------------------------------------------- */

        SET @StartTime = SYSDATETIME();

        PRINT '    Truncating Table: silver.ProductCategoryNameTranslation';
        TRUNCATE TABLE silver.ProductCategoryNameTranslation;

        PRINT '    Inserting Data Into: silver.ProductCategoryNameTranslation';
        INSERT INTO silver.ProductCategoryNameTranslation (
            ProductCategoryName,
            ProductCategoryNameEnglish,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(ProductCategoryName), ''),
            NULLIF(
                REPLACE(REPLACE(TRIM(ProductCategoryNameEnglish), CHAR(13), ''), CHAR(10), ''),
                ''
            ),
            SYSDATETIME()
        FROM bronze.ProductCategoryNameTranslation;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ============================================================================
           Commit Transaction
        ============================================================================ */

        COMMIT TRANSACTION;

        SET @EndTime = SYSDATETIME();

        PRINT 'Silver Layer Load Duration: ' + CAST(DATEDIFF(second, @BatchStartTime, @EndTime) AS NVARCHAR) + ' seconds';
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