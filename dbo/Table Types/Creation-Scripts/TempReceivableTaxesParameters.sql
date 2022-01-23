CREATE TYPE [dbo].[TempReceivableTaxesParameters] AS TABLE(
	[ReceivableId] [bigint] NOT NULL,
	[Currency] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount] [decimal](16, 2) NOT NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[IsCashBased] [bit] NOT NULL
)
GO
