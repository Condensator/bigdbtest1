CREATE TYPE [dbo].[TerminateTaxDepDetail] AS TABLE(
	[Id] [bigint] NULL,
	[PayOffAmount_Amount] [decimal](16, 2) NULL,
	[PayOffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxDepDisposalTemplateId] [bigint] NULL
)
GO
