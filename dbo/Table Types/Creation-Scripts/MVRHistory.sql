CREATE TYPE [dbo].[MVRHistory] AS TABLE(
	[MVRStatus] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MVRReviewedBy] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[MVRLastRunDate] [date] NULL,
	[MVRLastReviewedDate] [date] NULL,
	[Reason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[DriverId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
