CREATE TYPE [dbo].[PurgeTableConfig] AS TABLE(
	[TableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BatchSize] [int] NOT NULL,
	[ProcessingOrder] [int] NOT NULL,
	[PurgeFilter] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[ExistsInTempDb] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
