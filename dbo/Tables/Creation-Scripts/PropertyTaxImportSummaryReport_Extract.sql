SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertyTaxImportSummaryReport_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[JobId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[FileName] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[UploadedDate] [datetimeoffset](7) NOT NULL,
	[RecordsSuccessfullyUploaded] [bigint] NOT NULL,
	[RecordsErroredOut] [bigint] NOT NULL,
	[TotalTaxAmountUploaded] [decimal](16, 2) NOT NULL,
	[TotalTaxAmountErroredOut] [decimal](16, 2) NOT NULL,
	[Currency] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
