SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetReceivableTaxImpositionAmountSummary]
(
	@IsSummary BIT = 0
)
AS
BEGIN
	--DECLARE @IsSummary BIT = 0
	DECLARE @SalesTaxReceivableTaxSubset TABLE (
		[Id] [bigint] NOT NULL,
		[SequenceNumber] [nvarchar](40) NULL,
		[CustomerPartyNumber] [nvarchar](40) NULL,
		[EntityType] [nvarchar](2) NOT NULL,
		[DueDate] [date] NOT NULL,
		[ReceivableUniqueIdentifier] [nvarchar](30) NULL,
		[GLTemplateName] [nvarchar](40) NULL,
		[R_ReceivableId] [bigint] NULL
	)
	insert @SalesTaxReceivableTaxSubset 
	exec GetReceivableTaxAmountSummary 0,1

	DROP TABLE IF EXISTS #SalesTaxReceivableTaxSubset
	CREATE TABLE [dbo].#SalesTaxReceivableTaxSubset(
		[Id] [bigint] NOT NULL,
		[SequenceNumber] [nvarchar](40) NULL,
		[CustomerPartyNumber] [nvarchar](40) NULL,
		[EntityType] [nvarchar](2) NOT NULL,
		[DueDate] [date] NOT NULL,
		[ReceivableUniqueIdentifier] [nvarchar](30) NULL,
		[GLTemplateName] [nvarchar](40) NULL,
		[R_ReceivableId] [bigint] NULL
	)
	INSERT INTO #SalesTaxReceivableTaxSubset
	select * from @SalesTaxReceivableTaxSubset
	
		DROP TABLE IF EXISTS #SalesTaxReceivableTaxDetailSubset
		CREATE TABLE [dbo].#SalesTaxReceivableTaxDetailSubset(
			[Id] [bigint] NOT NULL,
			[AssetAlias] [nvarchar](100) NULL,
			[AssetLocationCode] [nvarchar](100) NULL,
			[LocationCode] [nvarchar](100) NULL,
			[UpfrontTaxMode] [nvarchar](6) NULL,
			[TaxBasisType] [nvarchar](2) NOT NULL,
			[Revenue_Amount] [decimal](16, 2) NOT NULL,
			[Revenue_Currency] [nvarchar](3) NOT NULL,
			[FairMarketValue_Amount] [decimal](16, 2) NOT NULL,
			[FairMarketValue_Currency] [nvarchar](3) NOT NULL,
			[Cost_Amount] [decimal](16, 2) NOT NULL,
			[Cost_Currency] [nvarchar](3) NOT NULL,
			[TaxAreaId] [bigint] NULL,
			[ManuallyAssessed] [bit] NOT NULL,
			[TaxCode] [nvarchar](40) NULL,
			[UpfrontPayableFactor] [decimal](10, 6) NOT NULL,
			[R_AssetLocationId] [bigint] NULL,
			[R_AssetLocation_LocationId] [bigint] NULL,
			[R_LocationId] [bigint] NULL,
			[R_AssetId] [bigint] NULL,
			[R_ReceivableDetailId] [bigint] NULL,
			[R_Amount_Amount] [decimal](16, 2) NOT NULL,
			[R_Amount_Currency] [nvarchar](3) NOT NULL,
			[R_TargetId] [bigint] NULL,
			[SalesTaxReceivableTaxId] [bigint] NOT NULL,
			[EntityType] [nvarchar](2) NOT NULL
		)

		DROP TABLE IF EXISTS #SalesTaxReceivableTaxImpositionSubset
		CREATE TABLE [dbo].#SalesTaxReceivableTaxImpositionSubset(
			[Id] [bigint] NOT NULL,
			[ExternalJurisdictionLevel] [nvarchar](200) NULL,
			[ExternalTaxImpositionType] [nvarchar](100) NULL,
			[TaxType] [nvarchar](40) NULL,
			[TaxBasisType] [nvarchar](2) NOT NULL,
			[ExemptionType] [nvarchar](21) NULL,
			[ExemptionRate] [decimal](10, 6) NOT NULL,
			[ExemptionAmount_Amount] [decimal](16, 2) NOT NULL,
			[ExemptionAmount_Currency] [nvarchar](3) NOT NULL,
			[TaxableBasisAmount_Amount] [decimal](16, 2) NOT NULL,
			[TaxableBasisAmount_Currency] [nvarchar](3) NOT NULL,
			[AppliedTaxRate] [decimal](10, 6) NOT NULL,
			[TaxAmount_Amount] [decimal](16, 2) NOT NULL,
			[TaxAmount_Currency] [nvarchar](3) NOT NULL,
			[R_TaxTypeId] [bigint] NULL,
			[R_ExternalJurisdictionLevelId] [bigint] NULL,
			[R_TargetId] [bigint] NULL,
			[SalesTaxReceivableTaxDetailId] [bigint] NOT NULL
		)

		INSERT INTO #SalesTaxReceivableTaxDetailSubset(Id,AssetAlias,AssetLocationCode,LocationCode,UpfrontTaxMode,TaxBasisType,Revenue_Amount,Revenue_Currency,FairMarketValue_Amount,FairMarketValue_Currency,Cost_Amount,Cost_Currency,TaxAreaId,ManuallyAssessed,TaxCode,UpfrontPayableFactor ,SalesTaxReceivableTaxId,EntityType,R_Amount_Amount,R_Amount_Currency)
		select stgSalesTaxReceivableTaxDetail.Id,AssetAlias,AssetLocationCode,LocationCode,UpfrontTaxMode,TaxBasisType,Revenue_Amount,Revenue_Currency,FairMarketValue_Amount,FairMarketValue_Currency,Cost_Amount,Cost_Currency,TaxAreaId,ManuallyAssessed,TaxCode,UpfrontPayableFactor ,SalesTaxReceivableTaxId,EntityType,0.00,Revenue_Currency
		from #SalesTaxReceivableTaxSubset 
		inner join stgSalesTaxReceivableTaxDetail WITH(NOLOCK) on stgSalesTaxReceivableTaxDetail.SalesTaxReceivableTaxId = #SalesTaxReceivableTaxSubset.Id

		INSERT INTO #SalesTaxReceivableTaxImpositionSubset(Id,ExternalJurisdictionLevel,ExternalTaxImpositionType,TaxType,TaxBasisType,ExemptionType,ExemptionRate,ExemptionAmount_Amount,ExemptionAmount_Currency,TaxableBasisAmount_Amount,TaxableBasisAmount_Currency,AppliedTaxRate,TaxAmount_Amount,TaxAmount_Currency,SalesTaxReceivableTaxDetailId)
		select stgSalesTaxReceivableTaxImposition.Id,ExternalJurisdictionLevel,ExternalTaxImpositionType,TaxType,stgSalesTaxReceivableTaxImposition.TaxBasisType,ExemptionType,ExemptionRate,ExemptionAmount_Amount,ExemptionAmount_Currency,TaxableBasisAmount_Amount,TaxableBasisAmount_Currency,AppliedTaxRate,TaxAmount_Amount,TaxAmount_Currency,SalesTaxReceivableTaxDetailId
		from #SalesTaxReceivableTaxDetailSubset 
		inner join stgSalesTaxReceivableTaxImposition WITH(NOLOCK) on stgSalesTaxReceivableTaxImposition.SalesTaxReceivableTaxDetailId = #SalesTaxReceivableTaxDetailSubset.Id
		
		CREATE NONCLUSTERED INDEX IX_SalesTaxReceivableTaxId ON #SalesTaxReceivableTaxSubset(Id);
		CREATE NONCLUSTERED INDEX IX_SalesTaxReceivableTaxDetailId ON #SalesTaxReceivableTaxDetailSubset(Id);
		CREATE NONCLUSTERED INDEX IX_SalesTaxReceivableTaxImpositionId ON #SalesTaxReceivableTaxImpositionSubset(Id);

		UPDATE salesTaxDetail SET R_AssetId = a.Id
		FROM 
			#SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK)
			INNER JOIN Assets a WITH (NOLOCK) ON a.Alias = salesTaxDetail.AssetAlias
		WHERE salesTaxDetail.AssetAlias IS NOT NULL

		UPDATE salesTaxDetail SET R_LocationId = l.Id
		FROM 
			#SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK)
			INNER JOIN Locations l WITH (NOLOCK) ON l.Code = salesTaxDetail.LocationCode
		WHERE salesTaxDetail.LocationCode IS NOT NULL

		UPDATE salesTaxDetail SET R_TargetId = rtd.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) ON salesTaxDetail.SalesTaxReceivableTaxId = salesTax.Id
			 INNER JOIN ReceivableTaxes rt WITH(NOLOCK) ON rt.ReceivableId = salesTax.R_ReceivableId 
			 INNER JOIN ReceivableTaxDetails rtd WITH(NOLOCK) ON rtd.ReceivableTaxId = rt.Id AND rtd.AssetId = salesTaxDetail.R_AssetId

		UPDATE salesTaxDetail SET R_TargetId = rtd.Id
		FROM #SalesTaxReceivableTaxSubset salesTax WITH(NOLOCK)
			 INNER JOIN #SalesTaxReceivableTaxDetailSubset salesTaxDetail WITH(NOLOCK) ON salesTaxDetail.SalesTaxReceivableTaxId = salesTax.Id
			 INNER JOIN ReceivableTaxes rt WITH(NOLOCK) ON rt.ReceivableId = salesTax.R_ReceivableId 
			 INNER JOIN ReceivableTaxDetails rtd WITH(NOLOCK) ON rtd.ReceivableTaxId = rt.Id
		WHERE salesTaxDetail.R_TargetId IS NULL
	
		UPDATE taxImposition SET TaxAmount_Amount = ROUND(taxImposition.AppliedTaxRate * taxImposition.TaxableBasisAmount_Amount, 2)
		FROM #SalesTaxReceivableTaxImpositionSubset taxImposition  WITH(NOLOCK)
		WHERE TaxAmount_Amount = 0.00 AND taxImposition.AppliedTaxRate != 0.00

		UPDATE taxImposition SET AppliedTaxRate = ROUND(taxImposition.TaxAmount_Amount / taxImposition.TaxableBasisAmount_Amount, 2)
		FROM #SalesTaxReceivableTaxImpositionSubset taxImposition  WITH(NOLOCK)
		WHERE TaxAmount_Amount != 0.00 AND taxImposition.AppliedTaxRate = 0.00  AND taxImposition.TaxableBasisAmount_Amount != 0.00

		UPDATE taxImposition SET R_ExternalJurisdictionLevelId = tac.Id
		FROM 
			#SalesTaxReceivableTaxImpositionSubset taxImposition WITH(NOLOCK)
			INNER JOIN TaxAuthorityConfigs tac ON tac.Description = taxImposition.ExternalJurisdictionLevel
		WHERE taxImposition.ExternalJurisdictionLevel IS NOT NULL

		UPDATE taxImposition SET R_TargetId = rti.Id
		FROM #SalesTaxReceivableTaxDetailSubset salesTaxDetail 
			 INNER JOIN #SalesTaxReceivableTaxImpositionSubset taxImposition  
			 ON taxImposition.SalesTaxReceivableTaxDetailId = salesTaxDetail.Id 
			 INNER JOIN ReceivableTaxDetails rtd ON rtd.Id = salesTaxDetail.R_TargetId
			 INNER JOIN ReceivableTaxImpositions rti ON rti.ReceivableTaxDetailId = rtd.Id 
			 AND rti.ExternalJurisdictionLevelId = taxImposition.R_ExternalJurisdictionLevelId
			 AND taxImposition.ExternalTaxImpositionType = rti.ExternalTaxImpositionType

	IF(@IsSummary = 1)
	BEGIN
		DROP TABLE IF EXISTS #Report
		CREATE TABLE [dbo].#Report
		(
			Intermediate_TotalNumberofRecords BIGINT,
			Intermediate_ExemptionAmount decimal(16,2),
			Intermediate_TaxAmount decimal(16,2),
			[Status] nvarchar(20),
			Target_TotalNumberofRecords BIGINT,
			Target_ExemptionAmount decimal(16,2),
			Target_TaxAmount decimal(16,2)
		)

		INSERT INTO #Report([Status],Target_TotalNumberofRecords,Intermediate_TotalNumberofRecords,
		Target_ExemptionAmount,Intermediate_ExemptionAmount,
		Target_TaxAmount,Intermediate_TaxAmount) 
		select 'Success',COUNT(*), COUNT(*), ISNULL(SUM(rti.ExemptionAmount_Amount),0), ISNULL(SUM(taxImposition.ExemptionAmount_Amount),0), ISNULL(SUM(rti.Amount_Amount),0), ISNULL(SUM(taxImposition.TaxAmount_Amount),0)
		FROM #SalesTaxReceivableTaxImpositionSubset taxImposition 
		LEFT JOIN ReceivableTaxImpositions rti ON taxImposition.R_TargetId = rti.Id

		INSERT INTO #Report([Status],Target_TotalNumberofRecords,
		Target_ExemptionAmount,
		Target_TaxAmount) 
		select 'Failed',COUNT(*), ISNULL(SUM(rti.ExemptionAmount_Amount),0), ISNULL(SUM(rti.Amount_Amount),0)
		FROM #SalesTaxReceivableTaxImpositionSubset taxImposition
		LEFT JOIN ReceivableTaxImpositions rti ON taxImposition.R_TargetId = rti.Id
		LEFT JOIN TaxAuthorityConfigs tac ON tac.Id = rti.ExternalJurisdictionLevelId
		LEFT JOIN TaxTypes tt ON tt.Id = rti.TaxTypeId
		WHERE (rti.ExemptionAmount_Amount != taxImposition.ExemptionAmount_Amount 
		OR rti.Amount_Amount != taxImposition.TaxAmount_Amount
		OR rti.TaxableBasisAmount_Amount != taxImposition.TaxableBasisAmount_Amount
		OR ISNULL(rti.ExemptionType,'') != ISNULL(taxImposition.ExemptionType,'')
		OR rti.ExemptionRate != taxImposition.ExemptionRate
		OR rti.AppliedTaxRate != taxImposition.AppliedTaxRate
		OR ISNULL(rti.ExternalTaxImpositionType,'') != ISNULL(taxImposition.ExternalTaxImpositionType,'')
		OR ISNULL(tt.Name,'') != ISNULL(taxImposition.TaxType,'')
		OR ISNULL(tac.Description,'') != ISNULL(taxImposition.ExternalJurisdictionLevel,'')
		OR ISNULL(rti.TaxBasisType,'') != ISNULL(taxImposition.TaxBasisType,''))
		AND taxImposition.R_TargetId IS NOT NULL

		INSERT INTO #Report([Status],Target_TotalNumberofRecords,Target_ExemptionAmount,Target_TaxAmount) 
		select 'Unable to Reconcile',COUNT(*), ISNULL(SUM(rti.ExemptionAmount_Amount),0), ISNULL(SUM(rti.Amount_Amount),0)
		FROM #SalesTaxReceivableTaxImpositionSubset taxImposition
		LEFT JOIN ReceivableTaxImpositions rti ON taxImposition.R_TargetId = rti.Id
		WHERE taxImposition.R_TargetId IS NULL
	
		UPDATE #Report SET 
		Target_TotalNumberofRecords = Target_TotalNumberofRecords - (SELECT SUM(Target_TotalNumberofRecords) FROM #Report WHERE Status != 'Success')
		,Target_ExemptionAmount = Target_ExemptionAmount - (SELECT SUM(Target_ExemptionAmount) FROM #Report WHERE Status != 'Success')
		,Target_TaxAmount = Target_TaxAmount - (SELECT SUM(Target_TaxAmount) FROM #Report WHERE Status != 'Success')
		WHERE Status = 'Success'

		SELECT * FROM #Report
	END
	ELSE
	BEGIN
		SELECT top 1048570 
		CASE
			WHEN taxImposition.R_TargetId IS NULL THEN 'Unable to Reconcile' ELSE 'Failed'
		END AS Status,
		taxImposition.Id IntermediateId,rti.Id TargetId,salesTax.EntityType,CustomerPartyNumber CustomerName,SequenceNumber,CAST(salesTax.DueDate as nvarchar(20)) DueDate,ReceivableUniqueIdentifier, 
		taxDetail.AssetAlias,ExternalJurisdictionLevel,taxImposition.ExternalTaxImpositionType
		,rti.Amount_Amount Target_Amount ,taxImposition.TaxAmount_Amount Intermediate_Amount
		,ISNULL(rti.Amount_Amount,0) - taxImposition.TaxAmount_Amount TaxAmount_Amount_Difference
		,rti.TaxableBasisAmount_Amount Target_TaxableBasisAmount ,taxImposition.TaxableBasisAmount_Amount Intermediate_TaxableBasisAmount
		,ISNULL(rti.TaxableBasisAmount_Amount,0) - taxImposition.TaxableBasisAmount_Amount TaxableBasis_Amount_Difference
		,rti.ExemptionAmount_Amount Target_ExemptionAmount ,taxImposition.ExemptionAmount_Amount Intermediate_ExemptionAmount
		,ISNULL(rti.ExemptionAmount_Amount,0) - taxImposition.ExemptionAmount_Amount ExemptionAmount_Difference
		,rti.ExemptionRate Target_ExemptionRate ,taxImposition.ExemptionRate  Intermediate_ExemptionRate
		,ISNULL(rti.ExemptionRate,0) - taxImposition.ExemptionRate ExemptionRate_Difference
		,rti.AppliedTaxRate Target_AppliedTaxRate ,taxImposition.AppliedTaxRate Intermediate_AppliedTaxRate
		,ISNULL(rti.AppliedTaxRate,0) - taxImposition.AppliedTaxRate AppliedTaxRate_Difference
		,rti.ExemptionType Target_ExemptionType ,taxImposition.ExemptionType  Intermediate_ExemptionType
		,rti.ExternalTaxImpositionType Target_ExternalTaxImpositionType ,taxImposition.ExternalTaxImpositionType Intermediate_ExternalTaxImpositionType
		,tt.Name Target_TaxType ,taxImposition.TaxType Intermediate_TaxType
		,tac.Description Target_ExternalJurisdictionLevel ,taxImposition.ExternalJurisdictionLevel Intermediate_ExternalJurisdictionLevel
		,rti.TaxBasisType Target_TaxBasisType ,taxImposition.TaxBasisType Intermediate_TaxBasisType
		FROM #SalesTaxReceivableTaxSubset salesTax
		INNER JOIN #SalesTaxReceivableTaxDetailSubset taxDetail ON salesTax.Id = taxDetail.SalesTaxReceivableTaxId
		INNER JOIN #SalesTaxReceivableTaxImpositionSubset taxImposition ON taxDetail.Id = taxImposition.SalesTaxReceivableTaxDetailId
		LEFT JOIN ReceivableTaxImpositions rti ON taxImposition.R_TargetId = rti.Id
		LEFT JOIN TaxAuthorityConfigs tac ON tac.Id = rti.ExternalJurisdictionLevelId
		LEFT JOIN TaxTypes tt ON tt.Id = rti.TaxTypeId
		WHERE rti.ExemptionAmount_Amount != taxImposition.ExemptionAmount_Amount 
		OR rti.Amount_Amount != taxImposition.TaxAmount_Amount
		OR rti.TaxableBasisAmount_Amount != taxImposition.TaxableBasisAmount_Amount
		OR ISNULL(rti.ExemptionType,'') != ISNULL(taxImposition.ExemptionType,'')
		OR ISNULL(rti.ExemptionRate,0) != ISNULL(taxImposition.ExemptionRate,0)
		OR ISNULL(rti.AppliedTaxRate,0) != ISNULL(taxImposition.AppliedTaxRate,0)
		OR ISNULL(rti.ExternalTaxImpositionType,'') != ISNULL(taxImposition.ExternalTaxImpositionType,'')
		OR ISNULL(tt.Name,'') != ISNULL(taxImposition.TaxType,'')
		OR ISNULL(tac.Description,'') != ISNULL(taxImposition.ExternalJurisdictionLevel,'')
		OR ISNULL(rti.TaxBasisType,'') != ISNULL(taxImposition.TaxBasisType,'')
		OR taxImposition.R_TargetId IS NULL
	END
END;

GO
