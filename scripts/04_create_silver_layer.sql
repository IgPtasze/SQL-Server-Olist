/*
===============================================================================
Silver Layer - Table Definitions
===============================================================================
Creates Silver layer tables used to store cleaned and standardized data.

The Silver layer contains data transformed from the Bronze layer, including
data type conversion, NULL handling and standardized column names.

LoadTimestamp records the time when each row was loaded into the Silver layer.
===============================================================================
*/

USE OlistDWH;
GO

/* ============================================================================
   Customer Data
============================================================================ */

DROP TABLE IF EXISTS silver.Customers;
GO

CREATE TABLE silver.Customers (
	Id				NVARCHAR(50),
	UniqueId		NVARCHAR(50),
	ZipCodePrefix	NVARCHAR(10),
	City			NVARCHAR(50),
	State			NVARCHAR(5),
	LoadTimestamp	DATETIME2
);
GO


/* ============================================================================
   Geolocation Data
============================================================================ */

DROP TABLE IF EXISTS silver.Geolocation;
GO

CREATE TABLE silver.Geolocation (
	ZipCodePrefix	NVARCHAR(10),
	Lat				DECIMAL(18,15),
	Lng				DECIMAL(18,15),
	City			NVARCHAR(50),
	State			NVARCHAR(5),
	LoadTimestamp	DATETIME2
);
GO


/* ============================================================================
   Order Item Data
============================================================================ */

DROP TABLE IF EXISTS silver.OrderItems;
GO

CREATE TABLE silver.OrderItems (
	OrderId				NVARCHAR(50),
	OrderItemId			INT,
	ProductId			NVARCHAR(50),
	SellerId			NVARCHAR(50),
	ShippingLimitDate	DATETIME2,
	Price				DECIMAL(10,2),
	FreightValue		DECIMAL(10,2),
	LoadTimestamp		DATETIME2
);
GO


/* ============================================================================
   Order Payment Data
============================================================================ */

DROP TABLE IF EXISTS silver.OrderPayments;
GO

CREATE TABLE silver.OrderPayments (
	OrderId			NVARCHAR(50),
	Sequential		INT,
	Type			NVARCHAR(20),
	Installments	INT,
	Value			DECIMAL(10,2),
	LoadTimestamp	DATETIME2
);
GO


/* ============================================================================
   Order Review Data
============================================================================ */

DROP TABLE IF EXISTS silver.OrderReviews;
GO

CREATE TABLE silver.OrderReviews (
	ReviewId		NVARCHAR(50),
	OrderId			NVARCHAR(50),
	Score			INT,
	CommentTitle	NVARCHAR(50),
	CommentMessage	NVARCHAR(500),
	CreationDate	DATETIME2,
	AnswerTimestamp	DATETIME2,
	LoadTimestamp	DATETIME2
);
GO


/* ============================================================================
   Order Data
============================================================================ */

DROP TABLE IF EXISTS silver.Orders;
GO

CREATE TABLE silver.Orders (
	Id						NVARCHAR(50),
	CustomerId				NVARCHAR(50),
	Status					NVARCHAR(20),
	PurchaseTimestamp		DATETIME2,
	ApprovedAt				DATETIME2,
	DeliveredCarrierDate	DATETIME2,
	DeliveredCustomerDate	DATETIME2,
	EstimatedDeliveryDate	DATETIME2,
	LoadTimestamp			DATETIME2
);
GO


/* ============================================================================
   Product Data
============================================================================ */

DROP TABLE IF EXISTS silver.Products;
GO

CREATE TABLE silver.Products (
	Id					NVARCHAR(50),
	CategoryName		NVARCHAR(60),
	NameLength			INT,
	DescriptionLength	INT,
	PhotosQty			INT,
	WeightG				INT,
	LengthCm			INT,
	HeightCm			INT,
	WidthCm				INT,
	LoadTimestamp		DATETIME2
);
GO


/* ============================================================================
   Seller Data
============================================================================ */

DROP TABLE IF EXISTS silver.Sellers;
GO

CREATE TABLE silver.Sellers (
	Id				NVARCHAR(50),
	ZipCodePrefix	NVARCHAR(10),
	City			NVARCHAR(50),
	State			NVARCHAR(5),
	LoadTimestamp	DATETIME2
);
GO


/* ============================================================================
   Product Category Name Translation Data
============================================================================ */

DROP TABLE IF EXISTS silver.ProductCategoryNameTranslation;
GO

CREATE TABLE silver.ProductCategoryNameTranslation (
	CategoryName			NVARCHAR(60),
	CategoryNameEnglish	NVARCHAR(60),
	LoadTimestamp		DATETIME2
);
GO