/*
===============================================================================
Database Initialization
===============================================================================
Creates the OlistDWH database and schemas used by the data warehouse layers:
- bronze - raw data loaded from source files
- silver - cleaned and standardized data
- gold   - dimensional model for analysis
===============================================================================
*/

USE master;
GO


/* ----------------------------------------------------------------------------
   Create Database
---------------------------------------------------------------------------- */

IF DB_ID(N'OlistDWH') IS NULL
BEGIN
	CREATE DATABASE OlistDWH;
END;
GO

USE OlistDWH;
GO

/* ----------------------------------------------------------------------------
   Create Schemas
---------------------------------------------------------------------------- */

IF SCHEMA_ID(N'bronze') IS NULL
BEGIN
	EXEC('CREATE SCHEMA bronze');
END;
GO

IF SCHEMA_ID(N'silver') IS NULL
BEGIN
	EXEC('CREATE SCHEMA silver');
END;
GO

IF SCHEMA_ID(N'gold') IS NULL
BEGIN
	EXEC('CREATE SCHEMA gold');
END;
GO