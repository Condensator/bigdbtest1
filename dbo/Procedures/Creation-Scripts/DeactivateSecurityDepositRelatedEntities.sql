SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeactivateSecurityDepositRelatedEntities]
(@ReceivableId							 BIGINT,
@CreatedById                            BIGINT,
@CreatedTime                            DATETIMEOFFSET,
@ErrorMessage							 NVARCHAR(MAX) OUT)
AS
BEGIN
SET NOCOUNT ON
BEGIN TRY
BEGIN TRANSACTION ProcessEntity;
WITH CTE_ReceiptApplicationReceivableDetails AS
(
SELECT
RARD.Id
FROM ReceiptApplications RA
JOIN ReceiptApplicationReceivableDetails RARD ON RA.Id = RARD.ReceiptApplicationId
JOIN ReceivableDetails RD ON RARD.ReceivableDetailId = RD.Id
JOIN Receivables R ON RD.ReceivableId = R.Id
WHERE R.Id = @ReceivableId
)
UPDATE ReceiptApplicationReceivableDetails
SET IsActive = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM CTE_ReceiptApplicationReceivableDetails
JOIN ReceiptApplicationReceivableDetails ON ReceiptApplicationReceivableDetails.Id = CTE_ReceiptApplicationReceivableDetails.Id;
WITH CTE_ReceivableInvoiceDetails AS
(
SELECT
RID.Id
FROM ReceivableInvoices RI
JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
JOIN Receivables R ON RD.ReceivableId = R.Id
WHERE R.Id = @ReceivableId
)
UPDATE ReceivableInvoiceDetails
SET IsActive = 0, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM CTE_ReceivableInvoiceDetails
JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.Id = CTE_ReceivableInvoiceDetails.Id;
COMMIT TRANSACTION ProcessEntity;
END TRY
BEGIN CATCH
SET @ErrorMessage = CAST(ERROR_MESSAGE() AS NVARCHAR(MAX));
PRINT  CAST(ERROR_MESSAGE() AS NVARCHAR(MAX));
ROLLBACK TRANSACTION ProcessEntity
END CATCH
END;

GO
