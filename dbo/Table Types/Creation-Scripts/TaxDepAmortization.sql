CREATE TYPE [dbo].[TaxDepAmortization] AS TABLE(
	[TaxBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FXTaxBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[FXTaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DepreciationBeginDate] [date] NOT NULL,
	[IsStraightLineMethodUsed] [bit] NOT NULL,
	[IsTaxDepreciationTerminated] [bit] NOT NULL,
	[TerminationDate] [date] NULL,
	[IsConditionalSale] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TaxDepreciationTemplateId] [bigint] NOT NULL,
	[TaxDepEntityId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
