CREATE TYPE [dbo].[InvoiceReportFileDetails] AS TABLE(
	[InvoiceId] [bigint] NULL,
	[Source] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Type] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL
)
GO
