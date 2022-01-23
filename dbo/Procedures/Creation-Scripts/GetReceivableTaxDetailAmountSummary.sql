SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetReceivableTaxDetailAmountSummary]
(
	@IsSummary BIT = NULL
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

		INSERT INTO #SalesTaxReceivableTaxDetailSubset(Id,AssetAlias,AssetLocationCode,LocationCode,UpfrontTaxMode,TaxBasisType,Revenue_Amount,Revenue_Currency,FairMarketValue_Amount,FairMarketValue_Currency,Cost_Amount,Cost_Currency,TaxAreaId,ManuallyAssessed,TaxCode,UpfrontPayableFactor ,SalesTaxReceivableTaxId,EntityType,R_Amount_Amount,R_Amount_Currency)
		select stgSalesTaxReceivableTaxDetail.Id,AssetAlias,AssetLocationCode,LocationCode,UpfrontTaxMode,TaxBasisType,Revenue_Amount,Revenue_Currency,FairMarketValue_Amount,FairMarketValue_Currency,Cost_Amount,Cost_Currency,TaxAreaId,ManuallyAssessed,TaxCode,UpfrontPayableFactor ,SalesTaxReceivableTaxId,EntityType,0.00,Revenue_Currency
		from #SalesTaxReceivableTaxSubset 
		inner join stgSalesTaxReceivableTaxDetail WITH(NOLOCK) on stgSalesTaxReceivableTaxDetail.SalesTaxReceivableTaxId = #SalesTaxReceivableTaxSubset.Id

		CREATE NONCLUSTERED INDEX IX_SalesTaxReceivableTaxId ON #SalesTaxReceivableTaxSubset(Id);
		CREATE NONCLUSTERED INDEX IX_SalesTaxReceivableTaxDetailId ON #SalesTaxReceivableTaxDetailSubset(Id);

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

	IF(@IsSummary = 1)
	BEGIN
		DROP TABLE IF EXISTS #Report
		CREATE TABLE [dbo].#Report
		(
			Intermediate_TotalNumberofRecords BIGINT,
			Intermediate_Revenue_Amount decimal(16,2),
			[Status] nvarchar(20),
			Target_TotalNumberofRecords BIGINT,
			Target_Revenue_Amount decimal(16,2)
		)

		INSERT INTO #Report([Status],Target_TotalNumberofRecords,Intermediate_TotalNumberofRecords,Target_Revenue_Amount,Intermediate_Revenue_Amount) 
		select 'Success',COUNT(*), COUNT(*), ISNULL(SUM(rtd.Revenue_Amount),0), ISNULL(SUM(taxDetail.Revenue_Amount),0)
		FROM #SalesTaxReceivableTaxDetailSubset taxDetail
		LEFT JOIN ReceivableTaxDetails rtd ON taxDetail.R_TargetId = rtd.Id

		INSERT INTO #Report([Status],Target_TotalNumberofRecords,Target_Revenue_Amount) 
		select 'Failed',COUNT(*), ISNULL(SUM(rtd.Revenue_Amount),0)
		FROM #SalesTaxReceivableTaxDetailSubset taxDetail
		LEFT JOIN ReceivableTaxDetails rtd ON taxDetail.R_TargetId = rtd.Id
		LEFT JOIN Locations l ON l.Id = rtd.LocationId
		LEFT JOIN AssetLocations al ON al.Id = rtd.AssetLocationId
		LEFT JOIN Locations l2 ON al.LocationId = l2.Id
		LEFT JOIN Assets a ON a.Id = rtd.AssetId
		WHERE (rtd.Revenue_Amount != taxDetail.Revenue_Amount
		OR ISNULL(rtd.UpfrontTaxMode,'') != ISNULL(taxDetail.UpfrontTaxMode,'')
		OR ISNULL(rtd.TaxBasisType,'') != ISNULL(taxDetail.TaxBasisType,'')
		OR rtd.Revenue_Amount != taxDetail.Revenue_Amount
		OR rtd.Cost_Amount != taxDetail.Cost_Amount
		OR rtd.FairMarketValue_Amount != taxDetail.FairMarketValue_Amount
		OR rtd.[ManuallyAssessed] != taxDetail.[ManuallyAssessed]
		OR rtd.[UpfrontPayableFactor] != taxDetail.[UpfrontPayableFactor]
		OR ISNULL(l2.Code,'') != ISNULL(taxDetail.AssetLocationCode,'')
		OR ISNULL(l.Code,'') != ISNULL(taxDetail.LocationCode,'')
		OR ISNULL(a.Alias,'') != ISNULL(taxDetail.AssetAlias,''))
		AND rtd.Id IS NOT NULL

		INSERT INTO #Report([Status],Target_TotalNumberofRecords,Target_Revenue_Amount) 
		select 'Unable to Reconcile',COUNT(*), ISNULL(SUM(rtd.Revenue_Amount),0)
		FROM #SalesTaxReceivableTaxDetailSubset taxDetail
		LEFT JOIN ReceivableTaxDetails rtd ON taxDetail.R_TargetId = rtd.Id
		WHERE taxDetail.R_TargetId IS NULL

		UPDATE #Report SET 
		Target_TotalNumberofRecords = Target_TotalNumberofRecords - (SELECT SUM(Target_TotalNumberofRecords) FROM #Report WHERE Status != 'Success')
		,Target_Revenue_Amount = Target_Revenue_Amount - (SELECT SUM(Target_Revenue_Amount) FROM #Report WHERE Status != 'Success')
		WHERE Status = 'Success'

		SELECT * FROM #Report
	END
	ELSE IF(@IsSummary = 0)
	BEGIN
		SELECT top 1048570 
		CASE
			WHEN rtd.Id IS NULL THEN 'Unable to Reconcile' ELSE 'Failed'
		END AS Status,
		taxDetail.Id IntermediateId,rtd.Id TargetId,salesTax.EntityType,CustomerPartyNumber CustomerName,SequenceNumber,CAST(salesTax.DueDate as nvarchar(20)) DueDate,ReceivableUniqueIdentifier, taxDetail.AssetAlias 
		,rtd.Revenue_Amount Target_Revenue_Amount, taxDetail.Revenue_Amount Intermediate_Revenue_Amount
		,ISNULL(rtd.Revenue_Amount,0) - taxDetail.Revenue_Amount Revenue_Amount_Difference
		,rtd.Cost_Amount Target_Cost_Amount,taxDetail.Cost_Amount Intermediate_Cost_Amount
		,ISNULL(rtd.Cost_Amount,0) - taxDetail.Cost_Amount Cost_Amount_Difference
		,rtd.FairMarketValue_Amount Target_FairMarketValue_Amount,taxDetail.FairMarketValue_Amount Intermediate_FairMarketValue_Amount
		,ISNULL(rtd.FairMarketValue_Amount,0) - taxDetail.FairMarketValue_Amount FairMarketValue_Amount_Difference
		,rtd.IsActive
		,rtd.IsGLPosted
		,rtd.[ManuallyAssessed] Target_ManuallyAssessed,taxDetail.[ManuallyAssessed] Intermediate_ManuallyAssessed
		,rtd.UpfrontTaxMode Target_UpfrontTaxMode, taxDetail.UpfrontTaxMode Intermediate_UpfrontTaxMode
		,rtd.TaxBasisType Target_TaxBasisType,taxDetail.TaxBasisType Intermediate_TaxBasisType
		,rtd.[UpfrontPayableFactor] Target_UpfrontPayableFactor, taxDetail.[UpfrontPayableFactor] Intermediate_UpfrontPayableFactor
		,l2.Code Target_AssetLocationCode, taxDetail.AssetLocationCode Intermediate_AssetLocationCode
		,l.Code Target_LocationCode, taxDetail.LocationCode Intermediate_LocationCode
		,a.Alias Target_AssetAlias, taxDetail.AssetAlias Intermediate_AssetAlias
		FROM #SalesTaxReceivableTaxSubset salesTax
		INNER JOIN #SalesTaxReceivableTaxDetailSubset taxDetail WITH(NOLOCK) on taxDetail.SalesTaxReceivableTaxId = salesTax.Id
		LEFT JOIN ReceivableTaxDetails rtd ON taxDetail.R_TargetId = rtd.Id
		LEFT JOIN Locations l ON l.Id = rtd.LocationId
		LEFT JOIN AssetLocations al ON al.Id = rtd.AssetLocationId
		LEFT JOIN Locations l2 ON al.LocationId = l2.Id
		LEFT JOIN Assets a ON a.Id = rtd.AssetId
		WHERE rtd.Revenue_Amount != taxDetail.Revenue_Amount
		OR ISNULL(rtd.UpfrontTaxMode,'') != ISNULL(taxDetail.UpfrontTaxMode,'')
		OR ISNULL(rtd.TaxBasisType,'') != ISNULL(taxDetail.TaxBasisType,'')
		OR rtd.Revenue_Amount != taxDetail.Revenue_Amount
		OR rtd.Cost_Amount != taxDetail.Cost_Amount
		OR rtd.FairMarketValue_Amount != taxDetail.FairMarketValue_Amount
		OR rtd.[ManuallyAssessed] != taxDetail.[ManuallyAssessed]
		OR rtd.[UpfrontPayableFactor] != taxDetail.[UpfrontPayableFactor]
		OR ISNULL(l2.Code,'') != ISNULL(taxDetail.AssetLocationCode,'')
		OR ISNULL(l.Code,'') != ISNULL(taxDetail.LocationCode,'')
		OR ISNULL(a.Alias,'') != ISNULL(taxDetail.AssetAlias,'')
		OR rtd.Id IS NULL
	END
	ELSE
	BEGIN
		SELECT * FROM #SalesTaxReceivableTaxDetailSubset
	END

END;

GO
