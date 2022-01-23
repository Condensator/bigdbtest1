CREATE TYPE [dbo].[ReceivableLECollection] AS TABLE(
	[ReceivableId] [bigint] NULL,
	[DueDate] [date] NULL,
	[LegalEntityId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[TaxLevel] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL
)
GO
