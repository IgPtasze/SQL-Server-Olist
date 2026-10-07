/*
===============================================================================
Bronze Layer - Table Definitions
===============================================================================
Creates Bronze layer tables used to store data loaded from source CSV files.

Source values are stored as NVARCHAR to preserve the original data before
type conversion and data cleansing in the Silver layer.
===============================================================================
*/

USE OlistDWH;
GO

/* ============================================================================
   Customer Data
============================================================================ */

DROP TABLE IF EXISTS bronze.Customers;
GO
CREATE TABLE bronze.Customers (
	Id				NVARCHAR(50),
	UniqueId		NVARCHAR(50),
	ZipCodePrefix	NVARCHAR(10),
	City			NVARCHAR(50),
	State			NVARCHAR(5)
);
GO

/* ============================================================================
   Geolocation Data
============================================================================ */

DROP TABLE IF EXISTS bronze.Geolocation;
GO
CREATE TABLE bronze.Geolocation (
	ZipCodePrefix	NVARCHAR(10),
	Lat				NVARCHAR(30),
	Lng				NVARCHAR(30),
	City			NVARCHAR(50),
	State			NVARCHAR(5)
);
GO

/* ============================================================================
   Order Item Data
============================================================================ */

DROP TABLE IF EXISTS bronze.OrderItems;
GO
CREATE TABLE bronze.OrderItems (
	OrderId				NVARCHAR(50),
	OrderItemId			NVARCHAR(5),
	ProductId			NVARCHAR(50),
	SellerId			NVARCHAR(50),
	ShippingLimitDate	NVARCHAR(20),
	Price				NVARCHAR(20),
	FreightValue		NVARCHAR(20)
);
GO

/* ============================================================================
   Order Payment Data
============================================================================ */

DROP TABLE IF EXISTS bronze.OrderPayments;
GO
CREATE TABLE bronze.OrderPayments (
	OrderId			NVARCHAR(50),
	Sequential		NVARCHAR(5),
	Type			NVARCHAR(20),
	Installments	NVARCHAR(5),
	Value			NVARCHAR(20)
);
GO

/* ============================================================================
   Order Review Data
============================================================================ */

DROP TABLE IF EXISTS bronze.OrderReviews;
GO
CREATE TABLE bronze.OrderReviews (
	ReviewId		NVARCHAR(50),
	OrderId			NVARCHAR(50),
	Score			NVARCHAR(5),
	CommentTitle	NVARCHAR(50),
	CommentMessage	NVARCHAR(500),
	CreationDate	NVARCHAR(20),
	AnswerTimestamp	NVARCHAR(20)
);
GO

/* ============================================================================
   Order Data
============================================================================ */

DROP TABLE IF EXISTS bronze.Orders;
GO
CREATE TABLE bronze.Orders (
	Id						NVARCHAR(50),
	CustomerId				NVARCHAR(50),
	Status					NVARCHAR(20),
	PurchaseTimestamp		NVARCHAR(20),
	ApprovedAt				NVARCHAR(20),
	DeliveredCarrierDate	NVARCHAR(20),
	DeliveredCustomerDate	NVARCHAR(20),
	EstimatedDeliveryDate	NVARCHAR(20)
);
GO

/* ============================================================================
   Product Data
============================================================================ */

DROP TABLE IF EXISTS bronze.Products;
GO
CREATE TABLE bronze.Products (
Id					NVARCHAR(50),
CategoryName		NVARCHAR(60),
NameLenght			NVARCHAR(5),
DescriptionLength	NVARCHAR(10),
PhotosQty			NVARCHAR(5),
WeightG				NVARCHAR(10),
LengthCm			NVARCHAR(10),
HeightCm			NVARCHAR(10),
WidthCm				NVARCHAR(10)
);
GO

/* ============================================================================
   Seller Data
============================================================================ */

DROP TABLE IF EXISTS bronze.Sellers;
GO
CREATE TABLE bronze.Sellers (
Id				NVARCHAR(50),
ZipCodePrefix	NVARCHAR(10),
City			NVARCHAR(50),
State			NVARCHAR(5)
);
GO


/* ============================================================================
   Product Category Translation Data
============================================================================ */

DROP TABLE IF EXISTS bronze.ProductCategoryNameTranslation;
GO
CREATE TABLE bronze.ProductCategoryNameTranslation (
CategoryName		NVARCHAR(60),
CategoryNameEnglish	NVARCHAR(60) 
);
GO