SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidatePayableInvoices]
(@UserId                  BIGINT,
@ModuleIterationStatusId BIGINT,
@CreatedTime             DATETIMEOFFSET,
@ProcessedRecords        BIGINT OUTPUT,
@FailedRecords           BIGINT OUTPUT
)
AS
BEGIN
CREATE TABLE #ErrorLogs
(Id                  BIGINT NOT NULL IDENTITY PRIMARY KEY,
StagingRootEntityId BIGINT,
Result              NVARCHAR(10),
Message             NVARCHAR(MAX)
);
CREATE TABLE #FailedProcessingLogs
([Id]               BIGINT NOT NULL,
[PayableInvoiceId] BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM dbo.stgPayableInvoice
WHERE IsMigrated = 0
);
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid legal entity number for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
LEFT JOIN dbo.LegalEntities le ON pi.LegalEntityNumber = le.LegalEntityNumber
AND le.STATUS = 'Active'
WHERE pi.LegalEntityNumber IS NOT NULL
AND IsMigrated = 0
AND le.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid asset cost payable code name for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
LEFT JOIN dbo.PayableCodes pc ON pi.AssetCostPayableCode = pc.Name
AND pc.IsActive = 1
WHERE pi.AssetCostPayableCode IS NOT NULL
AND IsMigrated = 0
AND pc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid currency for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
LEFT JOIN dbo.CurrencyCodes cc ON pi.Currency = cc.ISO
AND cc.IsActive = 1
LEFT JOIN dbo.Currencies c ON cc.Id = c.CurrencyCodeId
AND c.IsActive = 1
WHERE pi.Currency IS NOT NULL
AND IsMigrated = 0
AND c.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid contract currency for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
LEFT JOIN dbo.CurrencyCodes cc ON pi.ContractCurrency = cc.ISO
AND cc.IsActive = 1
LEFT JOIN dbo.Currencies c ON cc.Id = c.CurrencyCodeId
AND c.IsActive = 1
WHERE pi.ContractCurrency IS NOT NULL
AND IsMigrated = 0
AND c.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid line of business name for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
LEFT JOIN dbo.LineofBusinesses lb ON pi.LineofBusinessName = lb.Name
AND lb.IsActive = 1
WHERE pi.LineofBusinessName IS NOT NULL
AND IsMigrated = 0
AND lb.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid cost center name for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
LEFT JOIN dbo.CostCenterConfigs ccc ON ccc.CostCenter = pi.CostCenterName
AND ccc.IsActive = 1
WHERE pi.CostCenterName IS NOT NULL
AND IsMigrated = 0
AND ccc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid instrument type code for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
LEFT JOIN dbo.InstrumentTypes it ON it.Code = pi.InstrumentTypeCode
AND it.IsActive = 1
WHERE pi.InstrumentTypeCode IS NOT NULL
AND IsMigrated = 0
AND it.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid branch name for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
LEFT JOIN dbo.Branches b ON pi.BranchName = b.BranchName
AND b.STATUS = 'Active'
WHERE pi.BranchName IS NOT NULL
AND IsMigrated = 0
AND b.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid other cost code for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
INNER JOIN dbo.stgPayableInvoiceOtherCost pioc ON pi.Id = pioc.PayableInvoiceId
LEFT JOIN dbo.OtherCostCodes occ ON pioc.OtherCostCode = occ.Name
AND occ.IsActive = 1
WHERE pioc.OtherCostCode IS NOT NULL
AND IsMigrated = 0
AND occ.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid cost type name for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
INNER JOIN dbo.stgPayableInvoiceOtherCost pioc ON pi.Id = pioc.PayableInvoiceId
LEFT JOIN dbo.CostTypes ct ON pioc.CostTypeName = ct.Name
AND ct.IsActive = 1
WHERE pioc.CostTypeName IS NOT NULL
AND IsMigrated = 0
AND ct.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid receivable code name for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
INNER JOIN dbo.stgPayableInvoiceOtherCost pioc ON pi.Id = pioc.PayableInvoiceId
LEFT JOIN dbo.ReceivableCodes rc ON pioc.ReceivableCodeName = rc.Name
AND rc.IsActive = 1
WHERE pioc.ReceivableCodeName IS NOT NULL
AND IsMigrated = 0
AND rc.Id IS NULL;
INSERT INTO #ErrorLogs
SELECT DISTINCT
pi.Id
, 'Error'
, ('Invalid RemitToUniqueIdentifier for payable invoice {' + CONVERT(NVARCHAR(10), pi.Id) + '}') AS Message
FROM stgPayableInvoice pi
INNER JOIN dbo.stgPayableInvoiceOtherCost pioc ON pi.Id = pioc.PayableInvoiceId
INNER JOIN dbo.LegalEntities le ON pi.LegalEntityNumber = le.LegalEntityNumber
LEFT JOIN dbo.LegalEntityRemitToes lert ON le.Id = lert.LegalEntityId
LEFT JOIN dbo.RemitToes rt ON pioc.RemitToUniqueIdentifier = rt.UniqueIdentifier
AND rt.Id = lert.RemitToId
AND rt.IsActive = 1
WHERE pioc.RemitToUniqueIdentifier IS NOT NULL
AND IsMigrated = 0
AND rt.Id IS NULL;
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgPayableInvoice
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedPayableInvoices
ON(ProcessingLog.StagingRootEntityId = ProcessedPayableInvoices.Id
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ProcessedPayableInvoices.Id
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
INTO #CreatedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT 'Successful'
, 'Information'
, @UserId
, @CreatedTime
, Id
FROM #CreatedProcessingLogs;
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT DISTINCT
StagingRootEntityId
FROM #ErrorLogs
) AS ErrorPayableInvoices
ON(ProcessingLog.StagingRootEntityId = ErrorPayableInvoices.StagingRootEntityId
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
, UpdatedById = @UserId
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ErrorPayableInvoices.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorPayableInvoices.StagingRootEntityId
INTO #FailedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT #ErrorLogs.Message
, 'Error'
, @UserId
, @CreatedTime
, #FailedProcessingLogs.Id
FROM #ErrorLogs
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.PayableInvoiceId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
END;

GO
