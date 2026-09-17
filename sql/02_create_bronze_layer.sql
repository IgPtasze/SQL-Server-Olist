DROP TABLE IF EXISTS bronze.Customers
GO
CREATE TABLE bronze.Customers (
	Id				NVARCHAR(100),
	UniqueId		NVARCHAR(100),
	ZipCodePrefix	NVARCHAR(100),
	City			NVARCHAR(100),
	State			NVARCHAR(100)
);
GO

DROP TABLE IF EXISTS bronze.Geolocation
GO
CREATE TABLE bronze.Geolocation (
	ZipCodePrefix	NVARCHAR(100),
	Lat				NVARCHAR(100),
	Lng				NVARCHAR(100),
	City			NVARCHAR(100),
	State			NVARCHAR(100)
);
GO

DROP TABLE IF EXISTS bronze.OrderItems
GO
CREATE TABLE bronze.OrderItems (
	OrderId				NVARCHAR(100),
	ProductId			NVARCHAR(100),
	SellerId			NVARCHAR(100),
	ShippingLimitDate	NVARCHAR(100),
	Price				NVARCHAR(100),
	FreightValue		NVARCHAR(100)
);
GO

DROP TABLE IF EXISTS bronze.OrderPayments
GO
CREATE TABLE bronze.OrderPayments (
	OrderId				NVARCHAR(100),
	Sequential	NVARCHAR(100),
	Type			NVARCHAR(100),
	Installments	NVARCHAR(100),
	Value		NVARCHAR(100)
);
GO

DROP TABLE IF EXISTS bronze.OrderReviews
GO
CREATE TABLE bronze.OrderReviews (
	ReviewId		NVARCHAR(100),
	OrderId			NVARCHAR(100),
	Score			NVARCHAR(100),
	Comment_title	NVARCHAR(100),
	CommentMessage	NVARCHAR(100),
	CreationDate	NVARCHAR(100),
	AnswerTimestamp	NVARCHAR(100)
);
GO

DROP TABLE IF EXISTS bronze.Orders
GO
CREATE TABLE bronze.Orders (
	Id						NVARCHAR(100),
	CustomerId				NVARCHAR(100),
	Status					NVARCHAR(100),
	PurchaseTimestamp		NVARCHAR(100),
	ApprovedAt				NVARCHAR(100),
	DeliveredCarrierDate	NVARCHAR(100),
	DeliveredCustomerDate	NVARCHAR(100),
	EstimatedDeliveryDate	NVARCHAR(100)
);
GO

DROP TABLE IF EXISTS bronze.Products
GO
CREATE TABLE bronze.Products (
Id					NVARCHAR(100),
CategoryName		NVARCHAR(100),
NameLenght			NVARCHAR(100),
DescriptionLength	NVARCHAR(100),
PhotosQty			NVARCHAR(100),
WeightG				NVARCHAR(100),
LengthCm			NVARCHAR(100),
HeightCm			NVARCHAR(100),
WidthCm				NVARCHAR(100)
);
GO

DROP TABLE IF EXISTS bronze.Sellers
GO
CREATE TABLE bronze.Sellers (
Id		NVARCHAR(100),
City	NVARCHAR(100),
State	NVARCHAR(100)
);
GO

DROP TABLE IF EXISTS bronze.ProductCategoryNameTranslation
GO
CREATE TABLE bronze.ProductCategoryNameTranslation (
CategoryName		NVARCHAR(100),
CategoryNameEnglish	NVARCHAR(100)
);
GO