CREATE TYPE [dbo].[InvoiceReportDetails] AS TABLE(
	[InvoiceId] [bigint] NULL,
	[InvoiceFileName] [nvarchar](80) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFileSource] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFileType] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFileContent] [varbinary](1) NULL
)
GO
