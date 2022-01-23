CREATE TYPE [dbo].[LoanCaptalizedInterestToPersist] AS TABLE(
	[Source] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CapitalizedDate] [date] NULL,
	[Amount] [decimal](16, 2) NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PayableInvoiceOtherCostId] [bigint] NULL,
	[LoanFinanceId] [bigint] NULL
)
GO
