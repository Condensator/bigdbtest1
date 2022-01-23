SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreateExtractTables]
AS
BEGIN
DECLARE @DynamicSQL nvarchar(MAX);
DECLARE @LeaseIncomeRecognitionJobExtracts nvarchar(400)= 'tempdb..LeaseIncomeRecognitionJobExtracts_'+ DB_NAME();

IF OBJECT_ID(@LeaseIncomeRecognitionJobExtracts) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @LeaseIncomeRecognitionJobExtracts;
	EXEC(@DynamicSQL);
END
	SET @DynamicSQL = N'CREATE TABLE '+ @LeaseIncomeRecognitionJobExtracts + '(
		[Id] [bigint] IDENTITY(1,1) NOT NULL,
		[LeaseFinanceId] [bigint] NOT NULL,
		[TaskChunkServiceInstanceId] [bigint] NULL,
		[JobStepInstanceId] [bigint] NOT NULL,
		[IsSubmitted] [bit] NOT NULL,
		[PostDate] [date] NULL,
		[ProcessThroughDate] [date] NULL,
		[AssetCount] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
	) ON [PRIMARY]

	CREATE NONCLUSTERED INDEX IX_JobStepInstance ON ' + @LeaseIncomeRecognitionJobExtracts + '(JobStepInstanceId) INCLUDE (IsSubmitted,TaskChunkServiceInstanceId) WHERE IsSubmitted = 0

	CREATE NONCLUSTERED INDEX [IX_LeaseIncomeRecognitionJobExtract_LeaseFinance] ON ' + @LeaseIncomeRecognitionJobExtracts + '([LeaseFinanceId])';

	EXEC(@DynamicSQL);

DECLARE @PostReceivableToGLJobExtracts nvarchar(400)= 'tempdb..PostReceivableToGLJobExtracts_'+ DB_NAME();

IF OBJECT_ID(@PostReceivableToGLJobExtracts) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @PostReceivableToGLJobExtracts;
	EXEC(@DynamicSQL);
END
	SET @DynamicSQL = N'CREATE TABLE '+ @PostReceivableToGLJobExtracts + '
	(
		[Id] [bigint] IDENTITY(1,1) NOT NULL,
		[ReceivableId] [bigint] NULL,
		[ReceivableCode] [nvarchar](200) NULL,
		[AccountingTreatment] [nvarchar](24) NULL,
		[EntityType] [nvarchar](4) NULL,
		[DueDate] [date] NULL,
		[PostDate] [date] NULL,
		[ProcessThroughDate] [date] NULL,
		[CustomerId] [bigint] NULL,
		[IsIntercompany] [bit] NULL,
		[IsDSL] [bit] NULL,
		[IsSundryBlendedItemFAS91] [bit] NULL,
		[AcquisitionId] [nvarchar](80) NULL,
		[DealProductTypeId] [bigint] NULL,
		[BranchId] [bigint] NULL,
		[APGLTemplateId] [bigint] NULL,
		[SundryBlendedItemBookingGlTemplateId] [bigint] NULL,
		[ReceivableForTransferId] [bigint] NULL,
		[ReceivableForTransferType] [nvarchar](32) NULL,
		[GLTransactionType] [nvarchar](58) NULL,
		[SyndicationGLTransactionType] [nvarchar](58) NULL,
		[GLTemplateId] [bigint] NULL,
		[SyndicationGLTemplateId] [bigint] NULL,
		[FunderId] [bigint] NULL,
		[LegalEntityId] [bigint] NULL,
		[IncomeType] [nvarchar](32) NULL,
		[TotalAmount] [decimal](16, 2) NULL,
		[PrepaidAmount] [decimal](16, 2) NULL,
		[FinancingTotalAmount] [decimal](16, 2) NULL,
		[FinancingPrepaidAmount] [decimal](16, 2) NULL,
		[Currency] [nvarchar](80) NULL,
		[ContractType] [nvarchar](28) NULL,
		[ContractId] [bigint] NULL,
		[IsChargedOffContract] [bit] NULL,
		[InstrumentTypeId] [bigint] NULL,
		[BookingGLTemplateId] [bigint] NULL,
		[LineOfBusinessId] [bigint] NULL,
		[CostCenterId] [bigint] NULL,
		[LeaseInterimInterestIncomeGLTemplateId] [bigint] NULL,
		[LeaseInterimRentIncomeGLTemplateId] [bigint] NULL,
		[LoanIncomeRecognitionGLTemplateId] [bigint] NULL,
		[LoanInterimIncomeRecognitionGLTemplateId] [bigint] NULL,
		[CommencementDate] [date] NULL,
		[DiscountingId] [bigint] NULL,
		[ReceivableTaxId] [bigint] NULL,
		[TaxTotalAmount] [decimal](16, 2) NULL,
		[TaxBalanceAmount] [decimal](16, 2) NULL,
		[TaxCurrencyCode] [nvarchar](80) NULL,
		[TaxGlTemplateId] [bigint] NULL,
		[SecurityDepositId] [bigint] NULL,
		[IsCashBased] [bit] NULL,
		[ErrorMessage] [nvarchar](500) NULL,
		[TaskChunkServiceInstanceId] [bigint] NULL,
		[JobStepInstanceId] [bigint] NOT NULL,
		[IsSubmitted] [bit] NOT NULL,
		[IsReceivableValid] [bit] NOT NULL,
		[IsReceivableTaxValid] [bit] NOT NULL,
		[BlendedItemId] [bigint] NULL,
		[IsContractSyndicated] [bit] NOT NULL,
		[StartDate] [date] NULL,
		[ReceivableGlTransactionType] [nvarchar](58) NULL,
		[ReceivableIsCollected] [bit] NULL,
		[IsVendorOwned] [bit] NOT NULL,
		[IsTiedToDiscounting] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
	) ON [PRIMARY]

	CREATE NONCLUSTERED INDEX IX_JobStepInstance ON ' + @PostReceivableToGLJobExtracts + '(JobStepInstanceId) INCLUDE (IsSubmitted,TaskChunkServiceInstanceId) WHERE IsSubmitted = 0';

	EXEC(@DynamicSQL);

DECLARE @SalesTaxExtract nvarchar(max)= 'tempdb..SalesTaxReceivableDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' +  @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[LeaseAssetId] [bigint] NULL,
	[CustomerLocationId] [bigint] NULL,
	[AssetLocationId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL,
	[ReceivableDueDate] [date] NOT NULL,
	[ContractId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[EntityType] [nvarchar](40) NOT NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[Currency] [nvarchar](40) NOT NULL,
	[LocationId] [bigint] NULL,
	[PreviousLocationId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[AmountBilledToDate] [decimal](16, 2) NOT NULL,
	[IsExemptAtSundry] [bit] NOT NULL,
	[PaymentScheduleId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[IsVertexSupported] [bit] NOT NULL,
	[StateId] [bigint] NULL,
	[InvalidErrorCode] [nvarchar](4) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[DiscountingId] [bigint] NULL,
	[TaxPayer] [nvarchar](100) NULL,
	[GLTemplateId] [bigint] NULL,
	[LegalEntityTaxRemittancePreference] [nvarchar](40) NULL,
	[LegalEntityName] [nvarchar](100) NULL,
	[IsAssessSalesTaxAtSKULevel] [bit] NOT NULL,
	[AdjustmentBasisReceivableDetailId] [bigint] NULL,
	[IsOriginalReceivableDetailTaxAssessed] [bit] NULL,
	[SourceId] [bigint] NULL,
	[SourceTable] [nvarchar](20) NULL,
	[ReceivableTaxType] [nvarchar](8) NULL,
	[IsRenewal] [bit]  NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_JobStepInstanceId] ON ' + @SalesTaxExtract + '
(
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_SalesTaxReceivableDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId] ASC,
	[AssetId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..SalesTaxAssetDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[LeaseAssetId] [bigint] NULL,
	[IsExemptAtAsset] [bit] NOT NULL,
	[IsCapitalizedSalesTaxAsset] [bit] NOT NULL,
	[IsPrepaidUpfrontTax] [bit] NOT NULL,
	[NBVAmount] [decimal](16, 2) NOT NULL,
	[ContractId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[OriginalTaxBasisType] [nvarchar](5) NULL,
	[AcquisitionLocationId] [bigint] NULL,
	[IsSKU] [bit] NOT NULL,
	[CapitalizedOriginalAssetId] [bigint] NULL,
	[IsAssetFromOldFinance] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_SalesTaxAssetDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[LeaseFinanceId] ASC,
	[AssetId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..SalesTaxAssetLocationDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[LocationId] [bigint] NOT NULL,
	[PreviousLocationId] [bigint] NULL,
	[LocationTaxBasisType] [nvarchar](5) NULL,
	[ReciprocityAmount] [decimal](16, 2) NOT NULL,
	[LienCredit] [decimal](16, 2) NOT NULL,
	[LocationEffectiveDate] [date] NULL,
	[ReceivableDueDate] [date] NOT NULL,
	[AssetlocationId] [bigint] NULL,
	[CustomerLocationId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[UpfrontTaxAssessedInLegacySystem] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_SalesTaxAssetLocationDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId] ASC,
	[AssetId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..SalesTaxLocationDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + '(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LocationId] [bigint] NOT NULL,
	[City] [nvarchar](100) NULL,
	[StateShortName] [nvarchar](40) NULL,
	[CountryShortName] [nvarchar](40) NULL,
	[LocationStatus] [nvarchar](10) NULL,
	[LocationCode] [nvarchar](200) NOT NULL,
	[TaxAreaEffectiveDate] [date] NULL,
	[IsVertexSupportedLocation] [bit] NOT NULL,
	[StateId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[AcquisitionLocationTaxAreaId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_SalesTaxLocationDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[LocationId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..SalesTaxContractBasedSplitupReceivableDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + '(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[IsProcessed] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[CustomerCost] [decimal](16, 2) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_SalesTaxContractBasedSplitupReceivableDetail_Extract] ON ' + @SalesTaxExtract + ' 
(
	[ReceivableDetailId] ASC,
	[AssetId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VertexWSTransactionChunks_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BatchStatus] [nvarchar](10) NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_JobStepInstance] ON ' + @SalesTaxExtract + ' 
(
	[JobStepInstanceId] ASC
)
INCLUDE([BatchStatus]) WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VertexWSTransactionChunkDetails_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + '(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[VertexWSTransactionId] [bigint] NOT NULL,
	[VertexWSTransactionChunks_ExtractId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_JobStepInstance] ON ' + @SalesTaxExtract + '
(
	[VertexWSTransactionId] ASC,
	[JobStepInstanceId] ASC
)
INCLUDE([VertexWSTransactionChunks_ExtractId]) WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..SalesTaxAssetSKUDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + '(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetSKUId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[LeaseAssetId] [bigint] NULL,
	[LeaseAssetSKUId] [bigint] NULL,
	[IsExemptAtAssetSKU] [bit] NOT NULL,
	[NBVAmount] [decimal](16, 2) NOT NULL,
	[ContractId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_AssetSKUId_Extract] ON ' + @SalesTaxExtract + '
(
	[AssetSKUId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_SalesTaxAssetSKUDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[LeaseFinanceId] ASC,
	[AssetSKUId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..SalesTaxReceivableSKUDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[ReceivableSKUId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetSKUId] [bigint] NULL,
	[LeaseAssetSKUId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[AmountBilledToDate] [decimal](16, 2) NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_SalesTaxReceivableSKUDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId] ASC,
	[AssetSKUId] ASC,
	[JobStepInstanceId] ASC
)
INCLUDE([AmountBilledToDate],[ExtendedPrice],[ReceivableSKUId]) WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VertexAssetDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[TitleTransferCode] [nvarchar](40) NULL,
	[AssetType] [nvarchar](40) NULL,
	[SaleLeasebackCode] [nvarchar](40) NULL,
	[IsElectronicallyDelivered] [bit] NOT NULL,
	[GrossVehicleWeight] [decimal](16, 2) NOT NULL,
	[SalesTaxExemptionLevel] [nvarchar](40) NULL,
	[AssetCatalogNumber] [nvarchar](40) NULL,
	[ContractTypeName] [nvarchar](40) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Usage] [nvarchar](40) NULL,
	[ContractId] [bigint] NULL,
	[SalesTaxRemittanceResponsibility] [nvarchar](8) NULL,
	[PreviousSalesTaxRemittanceResponsibility] [nvarchar](8) NULL,
	[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate] [date] NULL,
	[AssetSerialOrVIN] [nvarchar](100) NULL,
	[AssetUsageCondition] [nvarchar](4) NULL,
	[IsSKU] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_VertexAssetDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[AssetId] ASC,
	[ContractId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VertexAssetSKUDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + '(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetSKUId] [bigint] NOT NULL,
	[AssetType] [nvarchar](40) NULL,
	[AssetCatalogNumber] [nvarchar](40) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Usage] [nvarchar](40) NULL,
	[ContractId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_VertexAssetSKUDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[AssetSKUId] ASC,
	[ContractId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VertexContractDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + '(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[SequenceNumber] [nvarchar](40) NOT NULL,
	[IsSyndicated] [bit] NOT NULL,
	[TaxRemittanceType] [nvarchar](40) NULL,
	[TaxAssessmentLevel] [nvarchar](10) NOT NULL,
	[DealProductTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[Term] [decimal](16, 2) NOT NULL,
	[BusCode] [nvarchar](40) NULL,
	[ShortLeaseType] [nvarchar](40) NULL,
	[IsContractCapitalizeUpfront] [bit] NOT NULL,
	[CommencementDate] [date] NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[NumberOfInceptionPayments] [int] NOT NULL,
	[ClassificationContractType] [nvarchar](100) NOT NULL,
	[IsLease] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[MaturityDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_VertexContractDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[ContractId] ASC,
	[LeaseFinanceId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VertexCustomerDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[CustomerName] [nvarchar](250) NOT NULL,
	[CustomerNumber] [nvarchar](40) NOT NULL,
	[ISOCountryCode] [nvarchar](5) NULL,
	[ClassCode] [nvarchar](40) NULL,
	[TaxRegistrationNumber] [nvarchar](20) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_VertexCustomerDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[CustomerId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VertexLocationTaxAreaDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + '(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LocationId] [bigint] NOT NULL,
	[TaxAreaId] [bigint] NULL,
	[ReceivableDueDate] [date] NOT NULL,
	[TaxAreaEffectiveDate] [date] NOT NULL,
	[AssetId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_VertexLocationTaxAreaDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[LocationId] ASC,
	[ReceivableDueDate] ASC,
	[AssetId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VertexReceivableCodeDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + '(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsExemptAtReceivableCode] [bit] NOT NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[SundryReceivableCode] [nvarchar](100) NOT NULL,
	[TaxReceivableName] [nvarchar](40) NULL,
	[IsRental] [bit] NOT NULL,
	[TransactionType] [nvarchar](100) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_VertexReceivableCodeDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[ReceivableCodeId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VertexWSTransaction_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + '(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[AmountBilledToDate] [decimal](16, 2) NULL,
	[City] [nvarchar](100) NULL,
	[LineItemNumber] [bigint] NULL,
	[CustomerCode] [nvarchar](100) NULL,
	[CurrencyCode] [nvarchar](40) NULL,
	[Cost] [decimal](16, 2) NULL,
	[CompanyCode] [nvarchar](100) NULL,
	[DueDate] [date] NULL,
	[MainDivision] [nvarchar](100) NULL,
	[Country] [nvarchar](100) NULL,
	[ExtendedPrice] [decimal](16, 2) NULL,
	[FairMarketValue] [decimal](16, 2) NULL,
	[LocationCode] [nvarchar](100) NULL,
	[Product] [nvarchar](100) NULL,
	[TaxAreaId] [bigint] NULL,
	[TransactionType] [nvarchar](100) NULL,
	[CustomerClass] [nvarchar](40) NULL,
	[Term] [decimal](16, 2) NULL,
	[GrossVehicleWeight] [int] NULL,
	[ReciprocityAmount] [decimal](16, 2) NULL,
	[LienCredit] [decimal](16, 2) NULL,
	[LocationEffectiveDate] [date] NULL,
	[TransCode] [nvarchar](40) NULL,
	[ContractTypeName] [nvarchar](40) NULL,
	[ShortLeaseType] [nvarchar](40) NULL,
	[TaxBasis] [nvarchar](40) NULL,
	[LeaseUniqueID] [nvarchar](40) NULL,
	[TitleTransferCode] [nvarchar](40) NULL,
	[SundryReceivableCode] [nvarchar](100) NULL,
	[AssetType] [nvarchar](40) NULL,
	[SaleLeasebackCode] [nvarchar](40) NULL,
	[IsElectronicallyDelivered] [bit] NOT NULL,
	[TaxRemittanceType] [nvarchar](40) NULL,
	[FromState] [nvarchar](100) NULL,
	[ToState] [nvarchar](100) NULL,
	[AssetId] [bigint] NULL,
	[SalesTaxExemptionLevel] [nvarchar](40) NULL,
	[TaxReceivableName] [nvarchar](40) NULL,
	[IsSyndicated] [bit] NOT NULL,
	[BusCode] [nvarchar](40) NULL,
	[HorsePower] [decimal](16, 2) NULL,
	[AssetCatalogNumber] [nvarchar](40) NULL,
	[IsTaxExempt] [bit] NOT NULL,
	[TaxExemptReason] [nvarchar](100) NULL,
	[IsPrepaidUpfrontTax] [bit] NOT NULL,
	[IsCapitalizedSalesTaxAsset] [bit] NOT NULL,
	[IsExemptAtAsset] [bit] NOT NULL,
	[IsExemptAtReceivableCode] [bit] NOT NULL,
	[IsExemptAtSundry] [bit] NOT NULL,
	[LocationId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[LocationStatus] [nvarchar](100) NULL,
	[BatchStatus] [nvarchar](10) NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Usage] [nvarchar](40) NULL,
	[IsCapitalizedFirstRealAsset] [bit] NOT NULL,
	[AssetLocationId] [bigint] NULL,
	[GLTemplateId] [bigint] NULL,
	[IsCapitalizedRealAsset] [bit] NOT NULL,
	[SalesTaxRemittanceResponsibility] [nvarchar](8) NULL,
	[AcquisitionLocationTaxAreaId] [bigint] NULL,
	[AcquisitionLocationCity] [nvarchar](100) NULL,
	[AcquisitionLocationMainDivision] [nvarchar](100) NULL,
	[AcquisitionLocationCountry] [nvarchar](100) NULL,
	[MaturityDate] [date] NULL,
	[AssetSerialOrVIN] [nvarchar](100) NULL,
	[AssetUsageCondition] [nvarchar](4) NULL,
	[CommencementDate] [date] NULL,
	[IsSKU] [bit] NOT NULL,
	[AssetSKUId] [bigint] NULL,
	[IsExemptAtAssetSKU] [bit] NOT NULL,
	[ReceivableSKUId] [bigint] NULL,
	[UpfrontTaxAssessedInLegacySystem] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_JobStepInstance] ON ' + @SalesTaxExtract + '
(
	[JobStepInstanceId] ASC
)
INCLUDE([ReceivableId],[TaxBasis]) WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_ReceivableDetail] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_VertexWSTransaction_Extract] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId] ASC,
	[AssetId] ASC,
	[AssetSKUId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VertexUpfrontCostDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + '(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[AssetCost] [decimal](16, 2) NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[AssetSKUId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_VertexUpfrontCostDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId] ASC,
	[AssetId] ASC,
	[AssetSKUId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VertexUpfrontRentalDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
    SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
	EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + '(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[FairMarketValue] [decimal](16, 2) NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[AssetSKUId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_VertexUpfrontRentalDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId] ASC,
	[AssetId] ASC,
	[AssetSKUId] ASC,
	[JobStepInstanceId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexAssetDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetId] BigInt  NOT NULL,
	[LeaseAssetId] BigInt  NULL,
	[ContractId] BigInt  NULL,
	[IsCountryTaxExempt] Bit  NOT NULL,
	[IsStateTaxExempt] Bit  NOT NULL,
	[IsCountyTaxExempt] Bit  NOT NULL,
	[IsCityTaxExempt] Bit  NOT NULL,
	[StateTaxTypeId] BigInt  NULL,
	[CountyTaxTypeId] BigInt  NULL,
	[CityTaxTypeId] BigInt  NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
	[SalesTaxRemittanceResponsibility] NVarChar(8)  NULL,
	[PreviousSalesTaxRemittanceResponsibility] NVarChar(8)  NULL,
	[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate] Date  NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_AssetDetail] ON ' + @SalesTaxExtract + '
(
	[AssetId],
	[ContractId],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexLocationDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LocationId] BigInt  NOT NULL,
	[JurisdictionId] BigInt  NOT NULL,
	[StateId] BigInt  NOT NULL,
	[StateShortName] NVarChar(40)  NULL,
	[CountryShortName] NVarChar(40)  NULL,
	[CountryId] BigInt  NOT NULL,
	[TaxBasisType] NVarChar(40)  NOT NULL,
	[UpfrontTaxMode] NVarChar(40)  NOT NULL,
	[IsCountryTaxExempt] Bit  NOT NULL,
	[IsStateTaxExempt] Bit  NOT NULL,
	[IsCountyTaxExempt] Bit  NOT NULL,
	[IsCityTaxExempt] Bit  NOT NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_Location] ON ' + @SalesTaxExtract + '
(
	[LocationId],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexReceivableCodeDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableCodeId] BigInt  NOT NULL,
	[StateId] BigInt  NULL,
	[IsExemptAtReceivableCode] Bit  NOT NULL,
	[IsRental] Bit  NOT NULL,
	[IsCountryTaxExempt] Bit  NOT NULL,
	[IsStateTaxExempt] Bit  NOT NULL,
	[IsCountyTaxExempt] Bit  NOT NULL,
	[IsCityTaxExempt] Bit  NOT NULL,
	[TaxReceivableName] NVarChar(100)  NULL,
	[TaxTypeId] BigInt  NOT NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_ReceivableCode] ON ' + @SalesTaxExtract + '
(
	[ReceivableCodeId],
	[StateId],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexCustomerDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerId] BigInt  NOT NULL,
	[ClassCode] NVarChar(40)  NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_Customer] ON ' + @SalesTaxExtract + '
(
	[CustomerId],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexLeaseDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LeaseFinanceId] BigInt  NOT NULL,
	[ContractId] BigInt  NOT NULL,
	[IsCountryTaxExempt] Bit  NOT NULL,
	[IsStateTaxExempt] Bit  NOT NULL,
	[IsCountyTaxExempt] Bit  NOT NULL,
	[IsCityTaxExempt] Bit  NOT NULL,
	[IsContractCapitalizeUpfront] Bit  NOT NULL,
	[IsLease] Bit  NOT NULL,
	[IsSyndicated] Bit  NOT NULL,
	[CommencementDate] Date  NULL,
	[NumberOfInceptionPayments] Int  NOT NULL,
	[ClassificationContractType] NVarChar(100)  NOT NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
	[SalesTaxRemittanceMethod] NVarChar(12)  NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_LeaseFinance] ON ' + @SalesTaxExtract + '
(
	[LeaseFinanceId],
	[ContractId],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexUpfrontRentalDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetId] BigInt  NOT NULL,
	[ReceivableDetailId] BigInt  NOT NULL,
	[FairMarketValue] Decimal(16,2)  NOT NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_NonVertexUpfrontRentalDetail] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId],
	[AssetId],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexUpfrontCostDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetId] BigInt  NOT NULL,
	[ReceivableDetailId] BigInt  NOT NULL,
	[AssetCost] Decimal(16,2)  NOT NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_NonVertexUpfrontCostDetail] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId],
	[AssetId],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexTaxExempt_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetId] BigInt  NULL,
	[ReceivableDetailId] BigInt  NOT NULL,
	[IsCountryTaxExempt] Bit  NOT NULL,
	[IsStateTaxExempt] Bit  NOT NULL,
	[IsCountyTaxExempt] Bit  NOT NULL,
	[IsCityTaxExempt] Bit  NOT NULL,
	[CountryTaxExemptRule] NVarChar(100)  NULL,
	[StateTaxExemptRule] NVarChar(100)  NULL,
	[CountyTaxExemptRule] NVarChar(100)  NULL,
	[CityTaxExemptRule] NVarChar(100)  NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_TaxExempt] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId],
	[AssetId],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexReceivableDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] BigInt  NOT NULL,
	[ReceivableDetailId] BigInt  NOT NULL,
	[ReceivableDueDate] Date  NOT NULL,
	[TaxTypeId] BigInt  NOT NULL,
	[AssetId] BigInt  NULL,
	[LocationId] BigInt  NOT NULL,
	[AssetLocationId] BigInt  NULL,
	[ExtendedPrice] Decimal(16,2)  NOT NULL,
	[FairMarketValue] Decimal(16,2)  NOT NULL,
	[AssetCost] Decimal(16,2)  NOT NULL,
	[Currency] NVarChar(40)  NOT NULL,
	[UpfrontTaxMode] NVarChar(40)  NOT NULL,
	[StateShortName] NVarChar(40)  NOT NULL,
	[PreviousStateShortName] NVarChar(40)  NULL,
	[IsUpFrontApplicable] Bit  NOT NULL,
	[ClassCode] NVarChar(40)  NULL,
	[JurisdictionId] BigInt  NOT NULL,
	[TaxBasisType] NVarChar(40)  NOT NULL,
	[StateTaxTypeId] BigInt  NULL,
	[CountyTaxTypeId] BigInt  NULL,
	[CityTaxTypeId] BigInt  NULL,
	[IsPrepaidUpfrontTax] Bit  NOT NULL,
	[IsCapitalizedSalesTaxAsset] Bit  NOT NULL,
	[IsCapitalizedRealAsset] Bit  NOT NULL,
	[IsExemptAtAsset] Bit  NOT NULL,
	[IsExemptAtReceivableCode] Bit  NOT NULL,
	[IsExemptAtSundry] Bit  NOT NULL,
	[LegalEntityId] BigInt  NOT NULL,
	[GLTemplateId] BigInt  NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
	[IsCapitalizedFirstRealAsset] Bit  NOT NULL,
	[CommencementDate] Date  NULL,
	[CountryShortName] NVarChar(40)  NULL,
	[SalesTaxRemittanceResponsibility] NVarChar(8)  NULL,
	[IsCashBased] Bit  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_ReceivableDetail] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId],
	[AssetId],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexTaxRateDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableDetailId] BigInt  NOT NULL,
	[AssetId] BigInt  NULL,
	[ImpositionType] NVarChar(40)  NOT NULL,
	[JurisdictionLevel] NVarChar(40)  NOT NULL,
	[TaxType] NVarChar(40)  NOT NULL,
	[EffectiveRate] Decimal(10,6)  NOT NULL,
	[TaxTypeId] BigInt  NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_TaxRate] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId],
	[AssetId],
	[JurisdictionLevel],
	[ImpositionType],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexImpositionLevelTaxDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableDetailId] BigInt  NOT NULL,
	[AssetId] BigInt  NULL,
	[ImpositionType] NVarChar(40)  NOT NULL,
	[JurisdictionLevel] NVarChar(40)  NOT NULL,
	[EffectiveRate] Decimal(10,6)  NOT NULL,
	[IsTaxExempt] Bit  NOT NULL,
	[TaxTypeId] BigInt  NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_ImpositionLevelTax] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId],
	[AssetId],
	[JurisdictionLevel],
	[ImpositionType],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..NonVertexTax_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] BigInt  NOT NULL,
	[ReceivableDetailId] BigInt  NOT NULL,
	[AssetId] BigInt  NULL,
	[Currency] NVarChar(40)  NOT NULL,
	[CalculatedTax] Decimal(16,2)  NOT NULL,
	[TaxResult] NVarChar(40)  NOT NULL,
	[JurisdictionId] BigInt  NOT NULL,
	[JurisdictionLevel] NVarChar(40)  NOT NULL,
	[ImpositionType] NVarChar(40)  NOT NULL,
	[EffectiveRate] Decimal(10,6)  NOT NULL,
	[ExemptionType] NVarChar(40)  NOT NULL,
	[ExemptionAmount] Decimal(16,2)  NOT NULL,
	[TaxTypeId] BigInt  NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
	[IsCashBased] Bit  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [UK_NonVertexTax] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId],
	[AssetId],
	[JurisdictionLevel],
	[ImpositionType],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VATReceivableLocationDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] BigInt  NULL,
	[ReceivableDueDate] Date  NULL,
	[CustomerId] BigInt  NULL,
	[LegalEntityId] BigInt  NULL,
	[ReceivableDetailId] BigInt  NOT NULL,
	[AssetId] BigInt  NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
	[ReceivableTypeId] BigInt  NOT NULL,
	[TaxLevel] NVarChar(7)  NOT NULL,
	[BuyerLocationId] BigInt  NOT NULL,
	[SellerLocationId] BigInt  NOT NULL,
	[TaxReceivableTypeId] BigInt  NULL,
	[PayableTypeId] BigInt  NULL,
	[TaxAssetTypeId] BigInt  NULL,
	[TaxRemittanceType] NVarChar(40)  NULL,
	[BuyerLocation] NVarChar(50)  NULL,
	[SellerLocation] NVarChar(50)  NULL,
	[TaxAssetType] NVarChar(40)  NULL,
	[TaxReceivableType] NVarChar(40)  NULL,
	[BuyerTaxRegistrationId] NVarChar(100)  NULL,
	[SellerTaxRegistrationId] NVarChar(100)  NULL,
	[IsCapitalizedUpfront] Bit  NOT NULL,
	[IsReceivableCodeTaxExempt] Bit  NOT NULL,
	[BasisAmount] Decimal(16,2)  NOT NULL,
	[BasisAmountCurrency] NVarChar(40)  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_VATLocationCodeDetail_Extract] ON ' + @SalesTaxExtract + '
(
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VATReceivableDetail_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] BigInt  NOT NULL,
	[ReceivableDetailId] BigInt  NOT NULL,
	[ReceivableDueDate] Date  NOT NULL,
	[AssetId] BigInt  NULL,
	[ReceivableDetailAmount] Decimal(16,2)  NOT NULL,
	[Currency] NVarChar(40)  NOT NULL,
	[GLTemplateId] BigInt  NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
	[TaxLevel] NVarChar(7)  NOT NULL,
	[BuyerLocationId] BigInt  NOT NULL,
	[SellerLocationId] BigInt  NOT NULL,
	[TaxReceivableTypeId] BigInt  NULL,
	[PayableTypeId] BigInt  NULL,
	[TaxAssetTypeId] BigInt  NULL,
	[IsCashBased] Bit  NOT NULL,
	[BatchStatus] NVarChar(10)  NULL,
	[TaxRemittanceType] NVarChar(40)  NULL,
	[BuyerLocation] NVarChar(50)  NULL,
	[SellerLocation] NVarChar(50)  NULL,
	[TaxAssetType] NVarChar(40)  NULL,
	[TaxReceivableType] NVarChar(40)  NULL,
	[IsCapitalizedUpfront] Bit  NOT NULL,
	[IsReceivableCodeTaxExempt] Bit  NOT NULL,
	[BuyerTaxRegistrationId] NVarChar(100)  NULL,
	[SellerTaxRegistrationId] NVarChar(100)  NULL,
	[IsLateFeeProcessed] Bit  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_ReceivableDetail] ON ' + @SalesTaxExtract + '
(
	[ReceivableDetailId],
	[AssetId],
	[JobStepInstanceId]
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VATReceivableDetailChunk_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BatchStatus] NVarChar(10)  NULL,
	[TaskChunkServiceInstanceId] BigInt  NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_VATReceivableDetailChunk_Extract] ON ' + @SalesTaxExtract + '
(
	[JobStepInstanceId]
)INCLUDE ([BatchStatus]) WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)

SET @SalesTaxExtract = 'tempdb..VATReceivableDetailChunkDetails_Extract_'+ DB_NAME();

IF OBJECT_ID(@SalesTaxExtract) IS NOT NULL
BEGIN
SET @DynamicSQL = N'DROP TABLE '+ @SalesTaxExtract;
EXEC(@DynamicSQL);
END
SET @DynamicSQL = N'CREATE TABLE ' + @SalesTaxExtract + ' (
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[VATReceivableDetail_ExtractId] BigInt  NOT NULL,
	[VATReceivableDetailChunk_ExtractId] BigInt  NOT NULL,
	[JobStepInstanceId] BigInt  NOT NULL,
PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_VATReceivableDetailChunkDetails_Extract] ON ' + @SalesTaxExtract + '
(
	[VATReceivableDetail_ExtractId],
	[JobStepInstanceId]
)INCLUDE ([VATReceivableDetailChunk_ExtractId]) WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 97) ON [PRIMARY]'
EXEC(@DynamicSQL)
END

GO
