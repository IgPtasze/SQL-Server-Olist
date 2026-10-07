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
	CustomerId				NVARCHAR(50),
	CustomerUniqueId		NVARCHAR(50),
	CustomerZipCodePrefix	NVARCHAR(10),
	CustomerCity			NVARCHAR(50),
	CustomerState			NVARCHAR(5)
);
GO

/* ============================================================================
   Geolocation Data
============================================================================ */

DROP TABLE IF EXISTS bronze.Geolocation;
GO
CREATE TABLE bronze.Geolocation (
	GeolocationZipCodePrefix	NVARCHAR(10),
	GeolocationLat				NVARCHAR(30),
	GeolocationLng				NVARCHAR(30),
	GeolocationCity				NVARCHAR(50),
	GeolocationState			NVARCHAR(5)
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
	OrderId				NVARCHAR(50),
	PaymentSequential	NVARCHAR(5),
	PaymentType			NVARCHAR(20),
	PaymentInstallments	NVARCHAR(5),
	PaymentValue		NVARCHAR(20)
);
GO

/* ============================================================================
   Order Review Data
============================================================================ */

DROP TABLE IF EXISTS bronze.OrderReviews;
GO
CREATE TABLE bronze.OrderReviews (
	ReviewId				NVARCHAR(50),
	OrderId					NVARCHAR(50),
	ReviewScore				NVARCHAR(5),
	ReviewCommentTitle		NVARCHAR(50),
	ReviewCommentMessage	NVARCHAR(500),
	ReviewCreationDate		NVARCHAR(20),
	ReviewAnswerTimestamp	NVARCHAR(20)
);
GO

/* ============================================================================
   Order Data
============================================================================ */

DROP TABLE IF EXISTS bronze.Orders;
GO
CREATE TABLE bronze.Orders (
	OrderId						NVARCHAR(50),
	CustomerId					NVARCHAR(50),
	OrderStatus					NVARCHAR(20),
	OrderPurchaseTimestamp		NVARCHAR(20),
	OrderApprovedAt				NVARCHAR(20),
	OrderDeliveredCarrierDate	NVARCHAR(20),
	OrderDeliveredCustomerDate	NVARCHAR(20),
	OrderEstimatedDeliveryDate	NVARCHAR(20)
);
GO

/* ============================================================================
   Product Data
============================================================================ */

DROP TABLE IF EXISTS bronze.Products;
GO
CREATE TABLE bronze.Products (
	ProductId					NVARCHAR(50),
	ProductCategoryName			NVARCHAR(60),
	ProductNameLenght			NVARCHAR(5),
	ProductDescriptionLenght	NVARCHAR(10),
	ProductPhotosQty			NVARCHAR(5),
	ProductWeightG				NVARCHAR(10),
	ProductLengthCm				NVARCHAR(10),
	ProductHeightCm				NVARCHAR(10),
	ProductWidthCm				NVARCHAR(10)
);
GO

/* ============================================================================
   Seller Data
============================================================================ */

DROP TABLE IF EXISTS bronze.Sellers;
GO
CREATE TABLE bronze.Sellers (
	SellerId				NVARCHAR(50),
	SellerZipCodePrefix		NVARCHAR(10),
	SellerCity				NVARCHAR(50),
	SellerState				NVARCHAR(5)
);
GO


/* ============================================================================
   Product Category Translation Data
============================================================================ */

DROP TABLE IF EXISTS bronze.ProductCategoryNameTranslation;
GO
CREATE TABLE bronze.ProductCategoryNameTranslation (
	ProductCategoryName			NVARCHAR(60),
	ProductCategoryNameEnglish	NVARCHAR(60) 
);
GO