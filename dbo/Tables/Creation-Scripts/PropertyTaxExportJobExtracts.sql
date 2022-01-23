SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertyTaxExportJobExtracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetID] [bigint] NULL,
	[TypeId] [bigint] NULL,
	[AssetCategoryId] [bigint] NULL,
	[ManufacturerId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[AcquisitionDate] [date] NULL,
	[SerialNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[IsEligibleForPropertyTax] [bit] NOT NULL,
	[PropertyTaxCost_Amount] [decimal](16, 2) NOT NULL,
	[PropertyTaxCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetCatalogId] [bigint] NULL,
	[ProductId] [bigint] NULL,
	[InServiceDate] [date] NULL,
	[AssetUsageCondition] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[SubStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[PropertyTaxReportCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[FinancialType] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[AssetStatus] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[AssetClassCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetLocationStateId] [bigint] NULL,
	[LocationEffectiveFromDate] [date] NULL,
	[LeaseContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[IsSyndicationResponsibilityRemitOnly] [bit] NULL,
	[ContractSyndicationType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[ContractOriginationSourceType] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[IsContractOriginationServiced] [bit] NULL,
	[PropertyTaxResponsibility] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[IsFederalIncomeTaxExempt] [bit] NULL,
	[BankQualified] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[IsSubmitted] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AssetLocationId] [bigint] NULL,
	[StateCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FileName] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[LienDate] [date] NULL,
	[DisposedDate] [date] NULL,
	[AsOfDate] [date] NULL,
	[SourceModule] [nvarchar](22) COLLATE Latin1_General_CI_AS NULL,
	[PreviousLeaseNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
