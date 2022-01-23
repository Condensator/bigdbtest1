CREATE TYPE [dbo].[PropertyTaxImportSummaryReport_Extract] AS TABLE(
	[JobId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[FileName] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[UploadedDate] [datetimeoffset](7) NOT NULL,
	[RecordsSuccessfullyUploaded] [bigint] NOT NULL,
	[RecordsErroredOut] [bigint] NOT NULL,
	[TotalTaxAmountUploaded] [decimal](16, 2) NOT NULL,
	[TotalTaxAmountErroredOut] [decimal](16, 2) NOT NULL,
	[Currency] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
