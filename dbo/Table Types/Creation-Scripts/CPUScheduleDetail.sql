CREATE TYPE [dbo].[CPUScheduleDetail] AS TABLE(
	[CPUScheduleId] [bigint] NOT NULL,
	[CPUAssetIds] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ReverseFromDate] [date] NULL
)
GO
