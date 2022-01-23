SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ExtractReceiptLockBoxBatchDetails]
(
@CreatedById						BIGINT,
@CreatedTime						DATETIMEOFFSET,
@JobStepInstanceId					BIGINT,
@PostDate							DATE,
@ReceiptClassificationValue_DSL		NVARCHAR(3)
)
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO Receipts_Extract
(ReceiptId, ReceiptNumber, Currency, PostDate, ReceivedDate, ReceiptClassification, LegalEntityId,
ReceiptBatchId, IsValid, JobStepInstanceId, CreatedById, CreatedTime, LineOfBusinessId, CostCenterId,
IsNewReceipt, DumpId)
SELECT
RPBL.Id
,CAST(NULL AS NVARCHAR) ReceiptNumber
,RPBL.Currency
,@PostDate
,RPBL.ReceivedDate
,RPBL.ReceiptClassification
,RPBL.LegalEntityId
,0 AS ReceiptBatchId
,RPBL.IsValid
,@JobStepInstanceId
,@CreatedById
,@CreatedTime
,RPBL.LineofBusinessId
,RPBL.CostCenterId
,CAST(1 AS BIT) AS IsNewReceipt
,RPBL.Id
FROM ReceiptPostByLockBox_Extract RPBL
WHERE (RPBL.ReceiptClassification <> @ReceiptClassificationValue_DSL OR RPBL.ReceiptClassification IS NULL)
AND RPBL.IsValid = 1 AND RPBL.JobStepInstanceId = @JobStepInstanceId
;
END

GO
