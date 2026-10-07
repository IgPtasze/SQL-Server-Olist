/*
===============================================================================
Gold Layer - Dimensional Model
===============================================================================
Creates the dimensional model used for analytical reporting.

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

Fact tables are created after dimensions because they contain foreign keys
referencing the dimension tables.
===============================================================================
*/

USE OlistDWH;
GO

/* ============================================================================
   Drop Existing Gold Tables
============================================================================ */

-- Fact tables must be dropped before dimensions because of foreign keys.
DROP TABLE IF EXISTS gold.fact_order_reviews;
DROP TABLE IF EXISTS gold.fact_order_payments;
DROP TABLE IF EXISTS gold.fact_order_items;
DROP TABLE IF EXISTS gold.fact_orders;

DROP TABLE IF EXISTS gold.dim_date;
DROP TABLE IF EXISTS gold.dim_seller;
DROP TABLE IF EXISTS gold.dim_product;
DROP TABLE IF EXISTS gold.dim_customer;
GO


/* ============================================================================
   Dimensions
============================================================================ */

/* ----------------------------------------------------------------------------
   Customer Dimension
---------------------------------------------------------------------------- */

CREATE TABLE gold.dim_customer (
    CustomerKey         INT IDENTITY(1,1) NOT NULL,
    CustomerUniqueId    NVARCHAR(50) NOT NULL,
    CustomerId          NVARCHAR(50) NOT NULL,
    ZipCodePrefix       NVARCHAR(10),
    City                NVARCHAR(50) COLLATE Latin1_General_CI_AI,
    State               NVARCHAR(5) COLLATE Latin1_General_CI_AI,

    CONSTRAINT PK_dim_customer
        PRIMARY KEY (CustomerKey),

    CONSTRAINT UQ_dim_customer_CustomerUniqueId
        UNIQUE (CustomerUniqueId)
);
GO


/* ----------------------------------------------------------------------------
   Product Dimension
---------------------------------------------------------------------------- */

CREATE TABLE gold.dim_product (
    ProductKey          INT IDENTITY(1,1) NOT NULL,
    ProductId           NVARCHAR(50) NOT NULL,
    CategoryName        NVARCHAR(100),
    CategoryNameEnglish NVARCHAR(100),
    PhotosQty           INT,
    WeightG             INT,
    LengthCM            INT,
    HeightCM            INT,
    WidthCM             INT,

    CONSTRAINT PK_dim_product
        PRIMARY KEY (ProductKey),

    CONSTRAINT UQ_dim_product_ProductId
        UNIQUE (ProductId)
);
GO


/* ----------------------------------------------------------------------------
   Seller Dimension
---------------------------------------------------------------------------- */

CREATE TABLE gold.dim_seller (
    SellerKey       INT IDENTITY(1,1) NOT NULL,
    SellerId        NVARCHAR(50) NOT NULL,
    ZipCodePrefix   NVARCHAR(10),
    City            NVARCHAR(50) COLLATE Latin1_General_CI_AI,
    State           NVARCHAR(5) COLLATE Latin1_General_CI_AI,

    CONSTRAINT PK_dim_seller
        PRIMARY KEY (SellerKey),

    CONSTRAINT UQ_dim_seller_SellerId
        UNIQUE (SellerId)
);
GO


/* ----------------------------------------------------------------------------
   Date Dimension
---------------------------------------------------------------------------- */

CREATE TABLE gold.dim_date (
    DateKey         INT NOT NULL,
    FullDate        DATE NOT NULL,
    Year            SMALLINT,
    Quarter         TINYINT,
    Month           TINYINT,
    MonthName       NVARCHAR(20),
    Week            TINYINT,
    DayOfMonth      TINYINT,
    DayOfWeek       TINYINT,
    DayName         NVARCHAR(20),
    IsWeekend       BIT,

    CONSTRAINT PK_dim_date
        PRIMARY KEY (DateKey),

    CONSTRAINT UQ_dim_date_FullDate
        UNIQUE (FullDate)
);
GO


/* ============================================================================
   Fact Tables
============================================================================ */

/* ----------------------------------------------------------------------------
   Orders Fact
---------------------------------------------------------------------------- */

CREATE TABLE gold.fact_orders (
    OrderKey            BIGINT IDENTITY(1,1) NOT NULL,
    OrderId             NVARCHAR(50) NOT NULL,
    CustomerKey         INT NOT NULL,
    PurchaseDateKey     INT NOT NULL,
    ApprovedDateKey     INT,
    CarrierDateKey      INT,
    DeliveredDateKey    INT,
    EstimatedDateKey    INT NOT NULL,
    OrderStatus         NVARCHAR(20) NOT NULL,
    ApprovalDays        INT,
    CarrierDays         INT,
    DeliveryDays        INT,
    IsDelivered         BIT NOT NULL,
    IsLate              BIT,
    OrderCount          INT NOT NULL,

    CONSTRAINT PK_fact_orders
        PRIMARY KEY (OrderKey),

    CONSTRAINT UQ_fact_orders_OrderId
        UNIQUE (OrderId),

    CONSTRAINT FK_fact_orders_Customer
        FOREIGN KEY (CustomerKey)
        REFERENCES gold.dim_customer (CustomerKey),

    CONSTRAINT FK_fact_orders_PurchaseDate
        FOREIGN KEY (PurchaseDateKey)
        REFERENCES gold.dim_date (DateKey),

    CONSTRAINT FK_fact_orders_ApprovedDate
        FOREIGN KEY (ApprovedDateKey)
        REFERENCES gold.dim_date (DateKey),

    CONSTRAINT FK_fact_orders_CarrierDate
        FOREIGN KEY (CarrierDateKey)
        REFERENCES gold.dim_date (DateKey),

    CONSTRAINT FK_fact_orders_DeliveredDate
        FOREIGN KEY (DeliveredDateKey)
        REFERENCES gold.dim_date (DateKey),

    CONSTRAINT FK_fact_orders_EstimatedDate
        FOREIGN KEY (EstimatedDateKey)
        REFERENCES gold.dim_date (DateKey)
);
GO


/* ----------------------------------------------------------------------------
   Order Items Fact
---------------------------------------------------------------------------- */

CREATE TABLE gold.fact_order_items (
    OrderItemKey        BIGINT IDENTITY(1,1) NOT NULL,
    OrderId             NVARCHAR(50) NOT NULL,
    OrderItemId         INT NOT NULL,
    CustomerKey         INT NOT NULL,
    ProductKey          INT NOT NULL,
    SellerKey           INT NOT NULL,
    PurchaseDateKey     INT NOT NULL,
    Price               DECIMAL(10,2) NOT NULL,
    FreightValue        DECIMAL(10,2) NOT NULL,
    ItemCount           INT NOT NULL,

    CONSTRAINT PK_fact_order_items
        PRIMARY KEY (OrderItemKey),

    CONSTRAINT UQ_fact_order_items_OrderItem
        UNIQUE (OrderId, OrderItemId),

    CONSTRAINT FK_fact_order_items_Customer
        FOREIGN KEY (CustomerKey)
        REFERENCES gold.dim_customer (CustomerKey),

    CONSTRAINT FK_fact_order_items_Product
        FOREIGN KEY (ProductKey)
        REFERENCES gold.dim_product (ProductKey),

    CONSTRAINT FK_fact_order_items_Seller
        FOREIGN KEY (SellerKey)
        REFERENCES gold.dim_seller (SellerKey),

    CONSTRAINT FK_fact_order_items_PurchaseDate
        FOREIGN KEY (PurchaseDateKey)
        REFERENCES gold.dim_date (DateKey)
);
GO


/* ----------------------------------------------------------------------------
   Order Payments Fact
---------------------------------------------------------------------------- */

CREATE TABLE gold.fact_order_payments (
    OrderPaymentKey        BIGINT IDENTITY(1,1) NOT NULL,
    OrderId                NVARCHAR(50) NOT NULL,
    PaymentSequential      INT NOT NULL,
    CustomerKey            INT NOT NULL,
    OrderPurchaseDateKey   INT NOT NULL,
    PaymentType            NVARCHAR(30) NOT NULL,
    PaymentValue           DECIMAL(10,2) NOT NULL,
    PaymentInstallments    INT NOT NULL,

    CONSTRAINT PK_fact_order_payments
        PRIMARY KEY (OrderPaymentKey),

    CONSTRAINT UQ_fact_order_payments_Payment
        UNIQUE (OrderId, PaymentSequential),

    CONSTRAINT FK_fact_order_payments_Customer
        FOREIGN KEY (CustomerKey)
        REFERENCES gold.dim_customer (CustomerKey),

    CONSTRAINT FK_fact_order_payments_OrderPurchaseDate
        FOREIGN KEY (OrderPurchaseDateKey)
        REFERENCES gold.dim_date (DateKey)
);
GO


/* ----------------------------------------------------------------------------
   Order Reviews Fact
---------------------------------------------------------------------------- */

CREATE TABLE gold.fact_order_reviews (
    OrderReviewKey          BIGINT IDENTITY(1,1) NOT NULL,
    OrderId                 NVARCHAR(50) NOT NULL,
    ReviewId                NVARCHAR(50) NOT NULL,
    CustomerKey             INT NOT NULL,
    ReviewCreationDateKey   INT NOT NULL,
    ReviewAnswerDateKey     INT,
    ReviewScore             INT NOT NULL,
    ReviewCount             INT NOT NULL,

    CONSTRAINT PK_fact_order_reviews
        PRIMARY KEY (OrderReviewKey),

    CONSTRAINT UQ_fact_order_reviews_Review
        UNIQUE (OrderId, ReviewId),

    CONSTRAINT FK_fact_order_reviews_Customer
        FOREIGN KEY (CustomerKey)
        REFERENCES gold.dim_customer (CustomerKey),

    CONSTRAINT FK_fact_order_reviews_CreationDate
        FOREIGN KEY (ReviewCreationDateKey)
        REFERENCES gold.dim_date (DateKey),

    CONSTRAINT FK_fact_order_reviews_AnswerDate
        FOREIGN KEY (ReviewAnswerDateKey)
        REFERENCES gold.dim_date (DateKey)
);
GO