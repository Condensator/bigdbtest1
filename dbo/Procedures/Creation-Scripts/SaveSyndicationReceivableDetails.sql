SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SaveSyndicationReceivableDetails]
(
	@ReceivableDetails SyndicationReceivableDetailsToSave READONLY,
	@CurrencyCode NVARCHAR(3),
	@CreatedByUserId BIGINT,
	@CreatedTime DATETIMEOFFSET
)
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

INSERT INTO [dbo].[ReceivableDetails] ([Amount_Amount],
[Amount_Currency],
[Balance_Amount],
[Balance_Currency],
[EffectiveBalance_Amount],
[EffectiveBalance_Currency],
[EffectiveBookBalance_Amount],
[EffectiveBookBalance_Currency],
[IsActive],
[BilledStatus],
[IsTaxAssessed],
[StopInvoicing],
[CreatedById],
[CreatedTime],
[AssetId],
[BillToId],
[AdjustmentBasisReceivableDetailId],
[ReceivableId],
[AssetComponentType],
[LeaseComponentAmount_Amount],
[LeaseComponentAmount_Currency],
[NonLeaseComponentAmount_Amount],
[NonLeaseComponentAmount_Currency],
[LeaseComponentBalance_Amount],
[LeaseComponentBalance_Currency],
[NonLeaseComponentBalance_Amount],
[NonLeaseComponentBalance_Currency],
[PreCapitalizationRent_Amount],
[PreCapitalizationRent_Currency])
		SELECT
			[Amount_Amount],
			@CurrencyCode,
			[Balance_Amount],
			@CurrencyCode,
			[EffectiveBalance_Amount],
			@CurrencyCode,
			[EffectiveBookBalance_Amount],
			@CurrencyCode,
			[IsActive],
			[BilledStatus],
			[IsTaxAssessed],
			[StopInvoicing],			
			@CreatedByUserId,
			@CreatedTime,
			[AssetId],
			[BillToId],
			[AdjustmentBasisReceivableDetailId],
			[ReceivableId],
			[AssetComponentType],
			[LeaseComponentAmount_Amount],
		    @CurrencyCode,
			[NonLeaseComponenAmount_Amount],
		    @CurrencyCode,
			[LeaseComponentBalance_Amount],
		    @CurrencyCode,
			[NonLeaseComponenBalance_Amount],
		    @CurrencyCode,
			[PreCapitalizationRent_Amount],
			@CurrencyCode
		FROM @ReceivableDetails;

SELECT 1;

END

GO
