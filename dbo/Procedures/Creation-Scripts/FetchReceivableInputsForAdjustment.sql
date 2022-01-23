SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[FetchReceivableInputsForAdjustment]
(
	@ReceivableIds ReceivableIdList READONLY,
	@ACHScheduleStatusPending NVARCHAR(7)
)
AS
BEGIN

DECLARE @IsLoan bit
SET @IsLoan =0

SET @IsLoan = (Select count( c.Id) from Contracts c
INNER JOIN Receivables r on c.Id = r.EntityId
INNER JOIN @ReceivableIds RId ON r.Id = RId.ReceivableId
where c.ContractType = 'Loan' or c.ContractType = 'ProgressLoan')

if(@IsLoan = 0)
BEGIN
SELECT
	Receivables.Id,
	EntityId,
	SourceId,
	EntityType,
	SourceTable,
	Receivables.CustomerId,
	Receivables.LegalEntityId,
	FunderId,
	Receivables.RemitToId,
	TaxRemitToId,
	AlternateBillingCurrencyId,
	LocationId,
	ReceivableCodeId,
	CurrencyCodes.ISO CurrencyCode,
	IsCollected,
	IsServiced,
	IsPrivateLabel,
	Receivables.InvoiceComment,
	ExchangeRate,
	DueDate,
	CalculatedDueDate,
	CreationSourceId,
	CreationSourceTable,
	InvoiceReceivableGroupingOption,
	IncomeType,
	IsDSL,
	Receivables.IsGLPosted,
	Receivables.IsDummy,
	PaymentScheduleId,
	CASE WHEN 
		Receivables.TotalAmount_Amount <> Receivables.TotalEffectiveBalance_Amount OR
		ISNULL(ReceivableTaxes.Amount_Amount,0.0) <> ISNULL(ReceivableTaxes.EffectiveBalance_Amount,0.0) 
	THEN 
		CAST(1 AS BIT) 
	ELSE 
		CAST(0 AS BIT) 
	END IsCashPosted,
	Contracts.ContractType,
	ReceivableTaxes.Id [ReceivableTaxId]
FROM
	Receivables
INNER JOIN @ReceivableIds ReceivableIds 
	ON Receivables.Id = ReceivableIds.ReceivableId
INNER JOIN Contracts
	ON Receivables.EntityId = Contracts.Id 
INNER JOIN Currencies 
	ON Contracts.CurrencyId = Currencies.Id
INNER JOIN CurrencyCodes 
	ON Currencies.CurrencyCodeId = CurrencyCodes.Id
LEFT JOIN ReceivableTaxes
	ON Receivables.Id = ReceivableTaxes.ReceivableId
    AND ReceivableTaxes.IsActive = 1
END

ELSE
BEGIN
SELECT
	Receivables.Id,
	EntityId,
	SourceId,
	EntityType,
	SourceTable,
	Receivables.CustomerId,
	Receivables.LegalEntityId,
	FunderId,
	Receivables.RemitToId,
	TaxRemitToId,
	AlternateBillingCurrencyId,
	LocationId,
	ReceivableCodeId,
	CurrencyCodes.ISO CurrencyCode,
	IsCollected,
	IsServiced,
	IsPrivateLabel,
	Receivables.InvoiceComment,
	ExchangeRate,
	DueDate,
	CalculatedDueDate,
	CreationSourceId,
	CreationSourceTable,
	InvoiceReceivableGroupingOption,
	IncomeType,
	IsDSL,
	Receivables.IsGLPosted,
	Receivables.IsDummy,
	PaymentScheduleId,
	CASE WHEN 
		Receivables.TotalAmount_Amount <> Receivables.TotalEffectiveBalance_Amount OR
		ISNULL(ReceivableTaxes.Amount_Amount,0.0) <> ISNULL(ReceivableTaxes.EffectiveBalance_Amount,0.0) 
	THEN 
		CAST(1 AS BIT) 
	ELSE 
		CAST(0 AS BIT) 
	END IsCashPosted,
	Contracts.ContractType,
	ReceivableTaxes.Id [ReceivableTaxId],
	LoanPrincipalReceivableCodeId
FROM
	Receivables
INNER JOIN @ReceivableIds ReceivableIds 
	ON Receivables.Id = ReceivableIds.ReceivableId
INNER JOIN Contracts
	ON Receivables.EntityId = Contracts.Id 
INNER JOIN LoanFinances
    ON LoanFinances.ContractId = Contracts.Id AND LoanFinances.IsCurrent =1
INNER JOIN Currencies 
	ON Contracts.CurrencyId = Currencies.Id
INNER JOIN CurrencyCodes 
	ON Currencies.CurrencyCodeId = CurrencyCodes.Id
LEFT JOIN ReceivableTaxes
	ON Receivables.Id = ReceivableTaxes.ReceivableId
    AND ReceivableTaxes.IsActive = 1
END

SELECT
	ReceivableDetails.Id,
	AssetId,
	BillToId,
	AdjustmentBasisReceivableDetailId,
	Amount_Amount Amount,
	LeaseComponentAmount_Amount LeaseComponentAmount,
	NonLeaseComponentAmount_Amount NonLeaseComponentAmount,
	Balance_Amount Balance,
	LeaseComponentBalance_Amount LeaseComponentBalance,
	NonLeaseComponentBalance_Amount NonLeaseComponentBalance,
	EffectiveBalance_Amount EffectiveBalance,
	EffectiveBookBalance_Amount EffectiveBookBalance,
	BilledStatus,
	IsTaxAssessed,
	StopInvoicing,
	AssetComponentType,
	ReceivableDetails.ReceivableId
FROM
	ReceivableDetails
INNER JOIN Receivables
	ON ReceivableDetails.ReceivableId = Receivables.Id
INNER JOIN @ReceivableIds ReceivableIds
	ON Receivables.id = ReceivableIds.ReceivableId
WHERE ReceivableDetails.IsActive = 1

	SELECT WHTTax.Id
			,TaxRate
			,BasisAmount_Amount
			,BasisAmount_Currency
			,Tax_Amount
			,Tax_Currency
			,WHTTax.ReceivableId
			,WithholdingTaxCodeDetailId
		FROM ReceivableWithholdingTaxDetails WHTTax
			INNER JOIN Receivables ON WHTTax.ReceivableId = Receivables.Id
			INNER JOIN @ReceivableIds ReceivableIds ON Receivables.id = ReceivableIds.ReceivableId
		WHERE WHTTax.IsActive = 1 			

	SELECT RecDetailWHTTax.Id
			,BasisAmount_Amount
			,BasisAmount_Currency
			,Tax_Amount
			,Tax_Currency
			,ReceivableDetailId
			,ReceivableWithholdingTaxDetailId 
		FROM ReceivableDetailsWithholdingTaxDetails RecDetailWHTTax
			INNER JOIN ReceivableDetails ON RecDetailWHTTax.ReceivableDetailId = ReceivableDetails.Id
			INNER JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
			INNER JOIN @ReceivableIds ReceivableIds ON Receivables.id = ReceivableIds.ReceivableId
		WHERE RecDetailWHTTax.IsActive = 1
			AND ReceivableDetails.IsActive = 1


SELECT 
	RentSharingDetails.Id,
	[Percentage], 
	[SourceType], 
	[VendorId] AS PartyId, 
	[PayableCodeId], 
	[RemitToId] AS RemitTo,
	RentSharingDetails.[ReceivableId]
FROM 
	RentSharingDetails
	INNER JOIN @ReceivableIds ReceivableIds ON RentSharingDetails.ReceivableId = ReceivableIds.ReceivableId
WHERE	
	RentSharingDetails.IsActive = 1


SELECT 
	ACHSchedules.Id AS ACHScheduleId,
	RecId.ReceivableId AS ReceivableId
FROM 
	ACHSchedules
	INNER JOIN @ReceivableIds RecId ON ACHSchedules.ReceivableId = RecId.ReceivableId
WHERE 
	ACHSchedules.Status = @ACHScheduleStatusPending
	AND ACHSchedules.IsActive = 1

END

GO
