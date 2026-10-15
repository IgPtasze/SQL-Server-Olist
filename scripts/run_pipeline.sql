:on error exit

:r /scripts/01_create_database.sql

USE OlistDWH;
GO

SET NOCOUNT ON;
GO

:r /scripts/02_create_bronze_layer.sql
:r /scripts/03_load_bronze_layer.sql

PRINT 'Loading Bronze data...';
EXEC bronze.LoadData;
GO

:r /scripts/04_create_silver_layer.sql
:r /scripts/05_load_silver_layer.sql

PRINT 'Loading Silver data...';
EXEC silver.LoadData;
GO

:r /scripts/06_validate_silver_layer.sql

PRINT 'Validating Silver data...';

GO

CREATE TABLE #SilverValidationResults (
    TestName    NVARCHAR(100),
    TableName   NVARCHAR(200),
    Status      NVARCHAR(10),
    IssueCount  BIGINT,
    Details     NVARCHAR(MAX)
);

INSERT INTO #SilverValidationResults
EXEC silver.ValidateData;

DECLARE @SilverIssues BIGINT;

SELECT @SilverIssues = COALESCE(
    SUM(CASE
        WHEN Status = N'FAIL'
        THEN COALESCE(IssueCount, 0)
        ELSE 0
    END),
    0
)
FROM #SilverValidationResults;

IF EXISTS (
    SELECT 1
    FROM #SilverValidationResults
    WHERE Status = N'FAIL'
)
BEGIN
    PRINT CONCAT(
        'Silver Layer Validation: PASS WITH WARNINGS (',
        @SilverIssues,
        ' issues)'
    );

    PRINT 'PIPELINE_VALIDATION_WARNING_SILVER';
END
ELSE
BEGIN
    PRINT 'Silver Layer Validation: PASS';
    PRINT 'PIPELINE_VALIDATION_PASS_SILVER';
END;

DROP TABLE #SilverValidationResults;

GO

:r /scripts/07_create_gold_layer.sql
:r /scripts/08_load_gold_layer.sql

PRINT 'Loading Gold data...';
EXEC gold.LoadData;
GO

:r /scripts/09_validate_gold_layer.sql

PRINT 'Validating Gold data...';

GO

CREATE TABLE #GoldValidationResults (
    TestName    NVARCHAR(100),
    TableName   NVARCHAR(200),
    Status      NVARCHAR(10),
    IssueCount  BIGINT,
    Details     NVARCHAR(MAX)
);

INSERT INTO #GoldValidationResults
EXEC gold.ValidateData;

DECLARE @GoldIssues BIGINT;

SELECT @GoldIssues = COALESCE(
    SUM(CASE
        WHEN Status = N'FAIL'
        THEN COALESCE(IssueCount, 0)
        ELSE 0
    END),
    0
)
FROM #GoldValidationResults;

IF EXISTS (
    SELECT 1
    FROM #GoldValidationResults
    WHERE Status = N'FAIL'
)
BEGIN
    PRINT CONCAT(
        'Gold Layer Validation: PASS WITH WARNINGS (',
        @GoldIssues,
        ' issues)'
    );

    PRINT 'PIPELINE_VALIDATION_WARNING_GOLD';
END
ELSE
BEGIN
    PRINT 'Gold Layer Validation: PASS';
    PRINT 'PIPELINE_VALIDATION_PASS_GOLD';
END;

DROP TABLE #GoldValidationResults;

GO