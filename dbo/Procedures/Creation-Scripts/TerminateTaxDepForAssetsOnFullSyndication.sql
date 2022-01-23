SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[TerminateTaxDepForAssetsOnFullSyndication]
(
@AssetIds NVARCHAR(MAX),
@SyndicationAtInception BIT,
@ContractId BIGINT,
@SyndicationEffectiveDate DATE,
@ActualProceedsAmount DECIMAL (16,2),
@TaxDepDisposalTemplateId BIGINT NULL,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE TD
SET	IsTaxDepreciationTerminated = 1,
TerminatedByLeaseId = @ContractId,
TerminationDate =
CASE
WHEN @SyndicationAtInception = 1 THEN @SyndicationEffectiveDate
ELSE DATEADD(DAY, -1, @SyndicationEffectiveDate)
END,
IsComputationPending = 1,
TaxProceedsAmount_Amount = @ActualProceedsAmount,
TaxDepDisposalTemplateId = @TaxDepDisposalTemplateId,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM TaxDepEntities TD
WHERE AssetId IN (SELECT
Id
FROM dbo.ConvertCSVToBigIntTable(@AssetIds, ','))
END

GO
