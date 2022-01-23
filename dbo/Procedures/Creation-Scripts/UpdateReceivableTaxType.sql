SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateReceivableTaxType]
(
	@ReceivableIds				IdCollection READONLY,
	@ReceivableTaxType_VAT		NVARCHAR(10),
	@ReceivableTaxType_SalexTax	NVARCHAR(10),
	@ReceivableEntityType_CT	NVARCHAR(5),
	@ReceivableEntityType_CU	NVARCHAR(5),
	@TaxSourceTableValues_CT	NVARCHAR(10),
	@UpdatedTime				DATETIMEOFFSET,
	@UpdatedById				BIGINT,
	@Count						INT	OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	-- Contract based receivables
	;WITH LatestTaxSource (ReceivableId, TaxSourceDetailId)
	AS (
		SELECT 
			Receivables.Id, MAX(TaxSourceDetails.Id)
		FROM Receivables 
		INNER JOIN @ReceivableIds IdList
			ON Receivables.Id = IdList.Id
		INNER JOIN TaxSourceDetails 		
			ON Receivables.EntityId = TaxSourceDetails.SourceId 
				AND Receivables.EntityType = @ReceivableEntityType_CT
				AND TaxSourceDetails.SourceTable = @TaxSourceTableValues_CT
				AND Receivables.DueDate >= TaxSourceDetails.EffectiveDate
		GROUP BY Receivables.Id 
	),
	LatestTaxSourceDetail (ReceivableId, TaxSourceDetailId, DealCountryId)
	AS (
		SELECT LatestTaxSource.ReceivableId, TaxSourceDetailId, DealCountryId FROM LatestTaxSource 
		INNER JOIN TaxSourceDetails 
			ON LatestTaxSource.TaxSourceDetailId = TaxSourceDetails.Id
	)
	UPDATE Receivables 
	SET Receivables.ReceivableTaxType = @ReceivableTaxType_VAT,
		Receivables.DealCountryId = LatestTaxSourceDetail.DealCountryId,
		Receivables.TaxSourceDetailId = LatestTaxSourceDetail.TaxSourceDetailId,
		Receivables.UpdatedTime = @UpdatedTime,
		Receivables.UpdatedById = @UpdatedById
	FROM Receivables 
	INNER JOIN LatestTaxSourceDetail ON LatestTaxSourceDetail.ReceivableId = Receivables.Id

	SET @Count = @@ROWCOUNT;

	-- Customer based receivables
	;WITH LatestTaxSource (ReceivableId, TaxSourceDetailId)
	AS (
		SELECT Receivables.Id, MAX(TaxSourceDetails.Id)
		FROM Receivables 
		INNER JOIN @ReceivableIds IdList
			ON Receivables.Id = IdList.Id
		INNER JOIN TaxSourceDetails 		
			ON Receivables.SourceId = TaxSourceDetails.SourceId 
				AND Receivables.SourceTable = TaxSourceDetails.SourceTable
				AND Receivables.EntityType = @ReceivableEntityType_CU
				AND Receivables.DueDate >= TaxSourceDetails.EffectiveDate
		GROUP BY Receivables.Id 
	),
	LatestTaxSourceDetail (ReceivableId, TaxSourceDetailId, DealCountryId)
	AS (
		SELECT LatestTaxSource.ReceivableId, TaxSourceDetailId, DealCountryId FROM LatestTaxSource 
		INNER JOIN TaxSourceDetails 
			ON LatestTaxSource.TaxSourceDetailId = TaxSourceDetails.Id
	)
	UPDATE Receivables 
	SET Receivables.ReceivableTaxType = @ReceivableTaxType_VAT,
		Receivables.DealCountryId = LatestTaxSourceDetail.DealCountryId,
		Receivables.TaxSourceDetailId = LatestTaxSourceDetail.TaxSourceDetailId,
		Receivables.UpdatedTime = @UpdatedTime,
		Receivables.UpdatedById = @UpdatedById
	FROM Receivables 
	INNER JOIN LatestTaxSourceDetail ON LatestTaxSourceDetail.ReceivableId = Receivables.Id

	SET @Count = @Count + @@ROWCOUNT;
	
	-- SalesTax receivable tax type
	UPDATE Receivables 
	SET Receivables.ReceivableTaxType = @ReceivableTaxType_SalexTax,
		Receivables.UpdatedTime = @UpdatedTime,
		Receivables.UpdatedById = @UpdatedById
	FROM Receivables
	INNER JOIN @ReceivableIds IdList
		ON Receivables.Id = IdList.Id
	WHERE Receivables.ReceivableTaxType = 'None'
	
	SET @Count = @Count + @@ROWCOUNT;
END

GO
