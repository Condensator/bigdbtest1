SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateInvoiceFileContents]
(
@InvoiceReportFileDetails InvoiceReportFileDetails READONLY,
@SourcePath NVARCHAR(4000),
@StorageSystem NVARCHAR(38),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SELECT * INTO #ReportDetails FROM (SELECT * FROM @InvoiceReportFileDetails reportDetails) AS repdet
CREATE TABLE #InsertedInvoice
(
[GUID] uniqueidentifier,
[SourceEntityId] BIGINT
)
INSERT INTO dbo.FileStores
(Source,FileType,GUID,StorageSystem,Content,ExtStoreReference,AccessKey,SourceEntity,SourceEntityId,SourceSystem,IsContentProcessed,IsActive,CreatedById,CreatedTime,UpdatedById,UpdatedTime,IsPreserveContentInLocal)
OUTPUT INSERTED.[GUID],INSERTED.[SourceEntityId] INTO #InsertedInvoice
SELECT
rd.[Source], -- Source - nvarchar
rd.[Type], -- FileType - nvarchar
NEWID(), -- GUID - uniqueidentifier
@StorageSystem, -- StorageSystem - nvarchar
NULL, -- Content - varbinary
@SourcePath + '\' + rd.[Source], -- ExtStoreReference - nvarchar
NULL, -- AccessKey - nvarchar
N'ReceivableInvoice', -- SourceEntity - nvarchar
ri.Id, -- SourceEntityId - nvarchar
N'LessorPortal', -- SourceSystem - nvarchar
1, -- IsContentProcessed - bit
1, -- IsActive - bit
@CreatedById, -- CreatedById - bigint
@CreatedTime, -- CreatedTime - datetimeoffset
NULL, -- UpdatedById - bigint
NULL, -- UpdatedTime - datetimeoffset
0 -- IsPreserveContentInLocal - bit
FROM dbo.ReceivableInvoices ri
INNER JOIN #ReportDetails rd ON rd.InvoiceId = ri.Id
WHERE (ri.JobStepInstanceId = @JobStepInstanceId Or @JobStepInstanceId = 0)
UPDATE dbo.ReceivableInvoices
SET
dbo.ReceivableInvoices.InvoiceFile_Source = rd.[Source],
dbo.ReceivableInvoices.InvoiceFile_Type = rd.[Type],
dbo.ReceivableInvoices.InvoiceFile_Content = Convert(varbinary(MAX),'GUID:'+ CONVERT(NVARCHAR(max), ii.[GUID])),
dbo.ReceivableInvoices.IsPdfGenerated = 1,
dbo.ReceivableInvoices.UpdatedById = @CreatedById,
dbo.ReceivableInvoices.UpdatedTime = @CreatedTime
FROM dbo.ReceivableInvoices ri
INNER JOIN #ReportDetails rd ON rd.InvoiceId = ri.Id
INNER JOIN #InsertedInvoice ii ON ii.SourceEntityId = ri.Id
WHERE (ri.JobStepInstanceId = @JobStepInstanceId Or @JobStepInstanceId = 0)
DROP TABLE #InsertedInvoice
DROP TABLE #ReportDetails
END

GO
