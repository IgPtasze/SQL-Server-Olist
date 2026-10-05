/*
===============================================================================
Stored Procedure: Load Data Into Silver Layer (Cleansed & Conformed)
===============================================================================
*/
USE OlistDWH;
GO

CREATE OR ALTER PROCEDURE silver.LoadData AS
BEGIN
    DECLARE @StartTime DATETIME2, @EndTime DATETIME2, @BatchStartTime DATETIME2;

    BEGIN TRY
        SET @BatchStartTime = SYSDATETIME();

        -- Wrap in an atomic transaction for pipeline failure safety (Docker execution)
        BEGIN TRANSACTION;

        PRINT 'Loading Data Into Silver Layer:';

        -- 1) Load data from bronze.Customers --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: silver.Customers';
        TRUNCATE TABLE silver.Customers;
    
        PRINT '    Inserting Data Into: silver.Customers';
        INSERT INTO silver.Customers (
            Id,
            UniqueId,
            ZipCodePrefix,
            City,
            State,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(Id), ''),
            NULLIF(TRIM(UniqueId), ''),
            NULLIF(TRIM(ZipCodePrefix), ''),
            NULLIF(TRIM(City), ''),
            NULLIF(REPLACE(REPLACE(TRIM(State), CHAR(13), ''), CHAR(10), ''), ''),
            SYSDATETIME()
        FROM bronze.Customers;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                    ';


        -- 2) Load data from bronze.Geolocation --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: silver.Geolocation';
        TRUNCATE TABLE silver.Geolocation;

        PRINT '    Inserting Data Into: silver.Geolocation';
        INSERT INTO silver.Geolocation (
            ZipCodePrefix,
            Lat,
            Lng,
            City,
            State,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(ZipCodePrefix), ''),
            TRY_CONVERT(DECIMAL(18,15), NULLIF(TRIM(Lat), '')),
            TRY_CONVERT(DECIMAL(18,15), NULLIF(TRIM(Lng), '')),
            NULLIF(TRIM(City), ''),
            NULLIF(REPLACE(REPLACE(TRIM(State), CHAR(13), ''), CHAR(10), ''), ''),
            SYSDATETIME()
        FROM bronze.Geolocation;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        -- 3) Load data from bronze.OrderItems --
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
            -- DATA QUALITY NOTE: Contains 3 orphan SellerIds missing from bronze.Sellers (olist_sellers_dataset).
            -- Retained in Silver to preserve order metrics; handled via an 'Unknown Member' (-1) in the Gold dimensional model.
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


        -- 4) Load data from bronze.OrderPayments --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: silver.OrderPayments';
        TRUNCATE TABLE silver.OrderPayments;

        PRINT '    Inserting Data Into: silver.OrderPayments';
        INSERT INTO silver.OrderPayments (
            OrderId,
            Sequential,
            Type,
            Installments,
            Value,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(OrderId), ''),
            TRY_CONVERT(INT, NULLIF(TRIM(Sequential), '')),
            NULLIF(TRIM(Type), ''),
            -- DATA QUALITY FIX: Handle 2 records with 0 installments.
            -- Map 0 installments to 1 (single-lump payment) to prevent division-by-zero errors in downstream financial metrics.
            CASE 
                WHEN TRY_CONVERT(INT, NULLIF(TRIM(Installments), '')) < 1 THEN 1 
                ELSE TRY_CONVERT(INT, NULLIF(TRIM(Installments), '')) 
            END,
            TRY_CONVERT(
                DECIMAL(10,2),
                NULLIF(REPLACE(REPLACE(TRIM(Value), CHAR(13), ''), CHAR(10), ''), '')
            ),
            SYSDATETIME()
        FROM bronze.OrderPayments;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        -- 5) Load data from bronze.OrderReviews --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: silver.OrderReviews';
        TRUNCATE TABLE silver.OrderReviews;

        PRINT '    Inserting Data Into: silver.OrderReviews';
        INSERT INTO silver.OrderReviews (
            ReviewId,
            OrderId,
            Score,
            CommentTitle,
            CommentMessage,
            CreationDate,
            AnswerTimestamp,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(ReviewId), ''),
            NULLIF(TRIM(OrderId), ''),
            TRY_CONVERT(INT, NULLIF(TRIM(Score), '')),
            NULLIF(TRIM(CommentTitle), ''),
            NULLIF(TRIM(CommentMessage), ''),
            TRY_CONVERT(DATETIME2, NULLIF(TRIM(CreationDate), '')),
            TRY_CONVERT(
                DATETIME2,
                NULLIF(REPLACE(REPLACE(TRIM(AnswerTimestamp), CHAR(13), ''), CHAR(10), ''), '')
            ),
            SYSDATETIME()
        FROM bronze.OrderReviews;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';
        

        -- 6) Load data from bronze.Orders --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: silver.Orders';
        TRUNCATE TABLE silver.Orders;

        PRINT '    Inserting Data Into: silver.Orders';
        INSERT INTO silver.Orders (
            Id,
            CustomerId,
            Status,
            PurchaseTimestamp,
            ApprovedAt,
            DeliveredCarrierDate,
            DeliveredCustomerDate,
            EstimatedDeliveryDate,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(Id), ''),
            NULLIF(TRIM(CustomerId), ''),
            NULLIF(TRIM(Status), ''),
            TRY_CONVERT(DATETIME2, NULLIF(TRIM(PurchaseTimestamp), '')),
            TRY_CONVERT(DATETIME2, NULLIF(TRIM(ApprovedAt), '')),
            -- DATA QUALITY FIX: Handle 166 records where carrier pickup predated purchase timestamp.
            -- Set invalid chronological carrier dates to NULL to preserve order entity integrity without distorting logistics KPIs.
            CASE 
                WHEN TRY_CONVERT(DATETIME2, NULLIF(TRIM(DeliveredCarrierDate), '')) < TRY_CONVERT(DATETIME2, NULLIF(TRIM(PurchaseTimestamp), '')) THEN NULL 
                ELSE TRY_CONVERT(DATETIME2, NULLIF(TRIM(DeliveredCarrierDate), '')) 
            END,
            TRY_CONVERT(DATETIME2, NULLIF(TRIM(DeliveredCustomerDate), '')),
            TRY_CONVERT(
                DATETIME2,
                NULLIF(REPLACE(REPLACE(TRIM(EstimatedDeliveryDate), CHAR(13), ''), CHAR(10), ''), '')
            ),
            SYSDATETIME()
        FROM bronze.Orders;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';
        

        -- 7) Load data from bronze.Products --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: silver.Products';
        TRUNCATE TABLE silver.Products;

        PRINT '    Inserting Data Into: silver.Products';
        INSERT INTO silver.Products (
            Id,
            CategoryName,
            NameLength,
            DescriptionLength,
            PhotosQty,
            WeightG,
            LengthCm,
            HeightCm,
            WidthCm,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(Id), ''),
            NULLIF(TRIM(CategoryName), ''),
            TRY_CONVERT(INT, NULLIF(TRIM(NameLenght), '')),
            TRY_CONVERT(INT, NULLIF(TRIM(DescriptionLength), '')),
            TRY_CONVERT(INT, NULLIF(TRIM(PhotosQty), '')),
            TRY_CONVERT(INT, NULLIF(TRIM(WeightG), '')),
            TRY_CONVERT(INT, NULLIF(TRIM(LengthCm), '')),
            TRY_CONVERT(INT, NULLIF(TRIM(HeightCm), '')),
            TRY_CONVERT(
                INT,
                NULLIF(REPLACE(REPLACE(TRIM(WidthCm), CHAR(13), ''), CHAR(10), ''), '')
            ),
            SYSDATETIME()
        FROM bronze.Products;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';
        

        -- 8) Load data from bronze.Sellers --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: silver.Sellers';
        TRUNCATE TABLE silver.Sellers;

        PRINT '    Inserting Data Into: silver.Sellers';
        INSERT INTO silver.Sellers (
            Id,
            ZipCodePrefix,
            City,
            State,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(Id), ''),
            NULLIF(TRIM(ZipCodePrefix), ''),
            NULLIF(TRIM(City), ''),
            NULLIF(REPLACE(REPLACE(TRIM(State), CHAR(13), ''), CHAR(10), ''), ''),
            SYSDATETIME()
        FROM bronze.Sellers;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';
        

        -- 9) Load data from bronze.ProductCategoryNameTranslation --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: silver.ProductCategoryNameTranslation';
        TRUNCATE TABLE silver.ProductCategoryNameTranslation;

        PRINT '    Inserting Data Into: silver.ProductCategoryNameTranslation';
        INSERT INTO silver.ProductCategoryNameTranslation (
            CategoryName,
            CategoryNameEnglish,
            LoadTimestamp
        )
        SELECT
            NULLIF(TRIM(CategoryName), ''),
            NULLIF(
                REPLACE(REPLACE(TRIM(CategoryNameEnglish), CHAR(13), ''), CHAR(10), ''),
                ''
            ),
            SYSDATETIME()
        FROM bronze.ProductCategoryNameTranslation;

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';

        -- Commit transaction if all table loads succeed
        COMMIT TRANSACTION;

        -- Calculate overall loading duration for the Silver layer
        SET @EndTime = SYSDATETIME();
        PRINT 'Silver Layer Load Duration: ' + CAST(DATEDIFF(second, @BatchStartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';

    END TRY
    BEGIN CATCH
        -- Rollback changes in case of failure to maintain consistent Silver state
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;

        PRINT '!!! ERROR OCCURRED DURING LOADING DATA !!!';
        PRINT CAST(ERROR_NUMBER() AS NVARCHAR) + ' - ' + ERROR_MESSAGE();
        
        -- Re-throw error to trigger exit code in Docker container
        THROW;
    END CATCH
END;
GO