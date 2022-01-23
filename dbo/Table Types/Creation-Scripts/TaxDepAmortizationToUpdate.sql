CREATE TYPE [dbo].[TaxDepAmortizationToUpdate] AS TABLE(
	[Id] [bigint] NULL,
	[TaxBasisAmount_Amount] [decimal](16, 2) NULL,
	[TaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FxTaxBasisAmount_Amount] [decimal](16, 2) NULL,
	[FxTaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DepreciationBeginDate] [date] NULL,
	[IsStraightLineMethodUsed] [bit] NULL,
	[IsTaxDepreciationTerminated] [bit] NULL,
	[TerminationDate] [date] NULL,
	[IsActive] [bit] NULL,
	[IsConditionalSale] [bit] NULL,
	[TaxDepreciationTemplateId] [bigint] NULL,
	[IsFromGeneration] [bit] NULL
)
GO
