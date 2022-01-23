CREATE TYPE [dbo].[CPUAssetMeterReadingErrorInfoForBulkProcess] AS TABLE(
	[Id] [bigint] NOT NULL,
	[EnmasseMeterReadingInstanceId] [bigint] NOT NULL,
	[Error] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NULL,
	[CreatedTime] [datetimeoffset](7) NULL
)
GO
