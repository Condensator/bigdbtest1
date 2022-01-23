CREATE TYPE [dbo].[PropertyTaxImportSummaryReportData] AS TABLE(
	[JobId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[FileName] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[UploadedDate] [datetimeoffset](7) NOT NULL,
	[RecordsSuccessfullyUploaded] [bigint] NOT NULL,
	[RecordsErroredOut] [bigint] NOT NULL,
	[TotalTaxAmountUploaded] [decimal](16, 2) NOT NULL,
	[TotalTaxAmountErroredOut] [decimal](16, 2) NOT NULL,
	[Currency] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL
)
GO
