CREATE TYPE [dbo].[LienSubmissionHistory] AS TABLE(
	[HistoryDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SubmissionStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[SubmissionError] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[LienFilingId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
