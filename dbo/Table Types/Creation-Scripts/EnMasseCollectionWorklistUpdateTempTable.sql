CREATE TYPE [dbo].[EnMasseCollectionWorklistUpdateTempTable] AS TABLE(
	[CollectionWorklistId] [bigint] NULL,
	[PrimaryCollectorId] [bigint] NULL,
	[Status] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[NextWorkDate] [date] NULL,
	[ClosureReason] [nvarchar](29) COLLATE Latin1_General_CI_AS NULL
)
GO
