SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateTaxDepForPayoffAssets]
(
@AssetIds TerminateTaxDepDetail READONLY,
@PayoffAtInception BIT,
@ContractId BIGINT,
@CommencementDate DATE,
@PayoffEffectiveDate DATE,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE TD
SET	IsTaxDepreciationTerminated = 1,
TerminatedByLeaseId = @ContractId,
TerminationDate = CASE WHEN @PayoffAtInception=1 THEN DATEADD(DAY, -1, @CommencementDate) ELSE @PayoffEffectiveDate END,
IsComputationPending = 1,
TaxProceedsAmount_Amount = SA.PayOffAmount_Amount,
TaxProceedsAmount_Currency = SA.PayOffAmount_Currency,
TaxDepDisposalTemplateId = SA.TaxDepDisposalTemplateId,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM TaxDepEntities TD
JOIN @AssetIds SA ON TD.AssetId = SA.Id
END

GO
