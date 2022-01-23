CREATE TYPE [dbo].[TaxDepEntityEnMasseUpdateDetail] AS TABLE(
	[IsComputationPending] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DepreciationBeginDate] [date] NOT NULL,
	[DepreciationEndDate] [date] NULL,
	[IsStraightLineMethodUsed] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsTaxDepreciationTerminated] [bit] NOT NULL,
	[TerminationDate] [date] NULL,
	[IsConditionalSale] [bit] NOT NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[FXTaxBasisAmountInLE_Amount] [decimal](16, 2) NOT NULL,
	[FXTaxBasisAmountInLE_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FXTaxBasisAmountInUSD_Amount] [decimal](16, 2) NOT NULL,
	[FXTaxBasisAmountInUSD_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxDepreciationTemplateId] [bigint] NOT NULL,
	[TaxDepDisposalGLTemplateId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[TaxDepEntityEnMasseUpdateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO