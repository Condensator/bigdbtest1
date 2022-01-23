CREATE TYPE [dbo].[LienRecordStatusHistory] AS TABLE(
	[HistoryDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RecordStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[FilingType] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[FilingStatus] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[FileNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FileDate] [date] NULL,
	[OriginalFileDate] [date] NULL,
	[ExpiryDate] [date] NULL,
	[FilingOffice] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[RejectedReason] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ResponseError] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[FilingStateId] [bigint] NOT NULL,
	[LienFilingId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
