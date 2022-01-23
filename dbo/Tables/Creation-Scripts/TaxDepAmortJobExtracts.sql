SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxDepAmortJobExtracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TaxDepEntityId] [bigint] NOT NULL,
	[TaxDepAmortizationId] [bigint] NULL,
	[DepreciationBeginDate] [date] NOT NULL,
	[DepreciationEndDate] [date] NULL,
	[TaxDepGLReversalDate] [date] NULL,
	[TerminationDate] [date] NULL,
	[TaxDepTemplateId] [bigint] NULL,
	[TaxBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FXTaxBasisAmount_Amount] [decimal](16, 2) NULL,
	[FXTaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[LeaseAssetId] [bigint] NULL,
	[BlendedItemId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[GLFinancialOpenPeriodFromDate] [date] NULL,
	[EtcBlendedItemTaxCreditTaxBasisPercentage] [decimal](16, 2) NULL,
	[AllowableCredit] [decimal](16, 2) NULL,
	[FiscalYearBeginMonth] [int] NULL,
	[FiscalYearEndMonth] [int] NULL,
	[IsGLPosted] [bit] NULL,
	[IsComputationPending] [bit] NULL,
	[IsAssetCountryUSA] [bit] NULL,
	[IsRecoverOverFixedTerm] [bit] NULL,
	[IsTaxDepreciationTerminated] [bit] NULL,
	[IsConditionalSale] [bit] NULL,
	[IsStraightLineMethodUsed] [bit] NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BlendedItemName] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[IsSubmitted] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxDepDisposalGLTemplateId] [bigint] NULL,
	[TaxAssetSetupGLTemplateId] [bigint] NULL,
	[TaxDepExpenseGLTemplateId] [bigint] NULL,
	[ContractCurrencyISO] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[TerminationFiscalYear] [int] NULL,
	[TaxProceedsAmount_Amount] [decimal](16, 2) NULL,
	[TaxProceedsAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CurrentTaxAssetSetupGLTemplateId] [bigint] NULL,
	[CurrentTaxDepExpenseGLTemplateId] [bigint] NULL,
	[ReversalPostDate] [date] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
