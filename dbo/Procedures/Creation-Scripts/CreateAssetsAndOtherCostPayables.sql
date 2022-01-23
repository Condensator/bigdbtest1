SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateAssetsAndOtherCostPayables]
(
@PayableHolderList PayableHolder READONLY ,
@PayableInvoiceId BIGINT,
@Currency VARCHAR(3),
@IsReversal BIT,
@PayableSourceAsset NVARCHAR(20),
@PayableSourceOtherCost NVARCHAR(50),
@PayableSourcePPCAsset NVARCHAR(50),
@AllocationMethod NVARCHAR(50),
@PayableInActiveStatus NVARCHAR(20),
@CreatedById NVARCHAR(25),
@CreatedTime DateTimeOffset
)
AS
BEGIN
SET NOCOUNT ON
IF @IsReversal=1
BEGIN
UPDATE Payables SET Status=@PayableInActiveStatus,UpdatedById=@CreatedById,UpdatedTime=@CreatedTime
FROM
Payables
JOIN PayableInvoiceAssets
ON Payables.SourceId=PayableInvoiceAssets.Id and Payables.SourceTable=@PayableSourceAsset
and PayableInvoiceAssets.PayableInvoiceId=@PayableInvoiceId
WHERE
Payables.Status <> @PayableInActiveStatus
UPDATE Payables SET Status=@PayableInActiveStatus,UpdatedById=@CreatedById,UpdatedTime=@CreatedTime
FROM
Payables
JOIN PayableInvoiceOtherCosts
ON Payables.SourceId=PayableInvoiceOtherCosts.Id and Payables.SourceTable=@PayableSourceOtherCost
and PayableInvoiceOtherCosts.PayableInvoiceId=@PayableInvoiceId
WHERE
Payables.Status <> @PayableInActiveStatus
UPDATE Payables SET Status=@PayableInActiveStatus,UpdatedById=@CreatedById,UpdatedTime=@CreatedTime
FROM
Payables
JOIN PayableInvoiceOtherCostDetails
ON Payables.SourceId=PayableInvoiceOtherCostDetails.Id
JOIN PayableInvoiceOtherCosts
ON PayableInvoiceOtherCostDetails.PayableInvoiceOtherCostId = PayableInvoiceOtherCosts.Id
WHERE
Payables.Status <> @PayableInActiveStatus
and Payables.SourceTable=@PayableSourcePPCAsset
and PayableInvoiceOtherCosts.PayableInvoiceId = @PayableInvoiceId
and PayableInvoiceOtherCosts.AllocationMethod = @AllocationMethod
END
INSERT INTO [dbo].[Payables]
(
[EntityType]
,[EntityId]
,[Amount_Amount]
,[Amount_Currency]
,[Balance_Amount]
,[Balance_Currency]
,[DueDate]
,[Status]
,[SourceTable]
,[SourceId]
,[InternalComment]
,[CreatedById]
,[CreatedTime]
,[CurrencyId]
,[PayableCodeId]
,[LegalEntityId]
,[PayeeId]
,[RemitToId]
,[IsGLPosted]
,[TaxPortion_Amount]
,[TaxPortion_Currency]
,[CreationSourceTable]
,WithholdingTaxRate
)
SELECT
'PI'
,@PayableInvoiceId
,Amount
,@Currency
,BalanceAmount
,@Currency
,DueDate
,ApprovalStatus
,Source
,SourceId
,InternalComment
,@CreatedById
,@CreatedTime
,CurrencyId
,PayableCodeId
,LegalEntityId
,PayeeId
,RemitToId
,0
,0.00
,@Currency
,'_'
,WithholdingTaxRate
FROM @PayableHolderList
END

GO
