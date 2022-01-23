SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ChangeStatusOfInactivePayableInvoiceAssets]
(
@PayableInvoiceId BIGINT,
@SourceModule NVARCHAR(50),
@ScrapStatus NVARCHAR(30),
@ErrorStatus NVARCHAR(30),
@Reason NVARCHAR(100),
@Real NVARCHAR(40),
@NegativeDeposit NVARCHAR(40),
@InvoiceDate DATETIMEOFFSET,
@UpdatedById bigint,
@UpdatedTime DATETIMEOFFSET,
@ActiveAssetIds NVARCHAR(MAX)=''
)
AS
BEGIN
SET NOCOUNT ON

SELECT
Assets.Id,
@ScrapStatus AS NewStatus INTO #NegativeAssetsToBeScrapped
FROM
Assets
INNER JOIN PayableInvoiceAssets
ON PayableInvoiceAssets.AssetId = Assets.Id AND
Assets.Status <> @ScrapStatus AND
Assets.FinancialType <> @NegativeDeposit AND
PayableInvoiceAssets.IsActive = 0
INNER JOIN PayableInvoices
ON PayableInvoices.Id = PayableInvoiceAssets.PayableInvoiceId
AND PayableInvoices.ParentPayableInvoiceId IS NULL
AND PayableInvoices.Id=@PayableInvoiceId
AND PayableInvoices.Status='InActive'
INSERT INTO #NegativeAssetsToBeScrapped
SELECT
Assets.Id,
(
CASE WHEN RealAssets.IsActive = 0 AND
PayableInvoiceDepositAssets.IsActive<> 0 THEN
@ScrapStatus
ELSE
@ErrorStatus
END
) as NewStatus
FROM
Assets
INNER JOIN PayableInvoiceAssets
ON PayableInvoiceAssets.AssetId = Assets.Id AND
Assets.Status <> @ErrorStatus AND
Assets.Status <> @ScrapStatus AND
Assets.FinancialType = @NegativeDeposit AND
PayableInvoiceAssets.IsActive = 0
AND PayableInvoiceAssets.PayableInvoiceId=@PayableInvoiceId
INNER JOIN PayableInvoiceDepositTakeDownAssets
ON PayableInvoiceAssets.Id =PayableInvoiceDepositTakeDownAssets.NegativeDepositAssetId
INNER JOIN PayableInvoiceDepositAssets
ON PayableInvoiceDepositTakeDownAssets.PayableInvoiceDepositAssetId=PayableInvoiceDepositAssets.Id
LEFT JOIN  PayableInvoiceAssets as RealAssets
ON PayableInvoiceDepositTakeDownAssets.TakeDownAssetId=RealAssets.Id
UPDATE Assets SET Status = #NegativeAssetsToBeScrapped.NewStatus,PropertyTaxCost_Amount = 0.0,UpdatedById = @UpdatedById,UpdatedTime = @UpdatedTime
FROM
Assets A
INNER JOIN #NegativeAssetsToBeScrapped
ON A.Id = #NegativeAssetsToBeScrapped.Id
WHERE NOT EXISTS(Select * from PayableInvoiceAssets where Assetid = #NegativeAssetsToBeScrapped.Id and IsActive=1 ) AND (@ActiveAssetIds != '' AND A.Id in (SELECT Id FROM ConvertCSVToBigIntTable(@ActiveAssetIds, ',')))


INSERT INTO AssetHistories
(
[Reason]
,[AsOfDate]
,[AcquisitionDate]
,[Status]
,[FinancialType]
,[SourceModule]
,[SourceModuleId]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
--,[ContractId]
,[AssetId]
,[IsReversed]
,[PropertyTaxReportCodeId])
SELECT
@Reason,
@InvoiceDate,
Assets.AcquisitionDate,
NewStatus,
Assets.FinancialType,
@SourceModule,
@PayableInvoiceId,
@UpdatedById,
@UpdatedTime,
NULL,
NULL,
Assets.CustomerId,
Assets.ParentAssetId,
Assets.LegalEntityId,
--NULL,
Assets.Id,
0,
Assets.PropertyTaxReportCodeId
FROM
Assets
INNER JOIN #NegativeAssetsToBeScrapped
ON Assets.Id = #NegativeAssetsToBeScrapped.Id
WHERE NOT EXISTS(Select * from PayableInvoiceAssets where Assetid = #NegativeAssetsToBeScrapped.Id and IsActive=1 ) AND (@ActiveAssetIds != '' AND Assets.Id in (SELECT Id FROM ConvertCSVToBigIntTable(@ActiveAssetIds, ',')))

END

GO
