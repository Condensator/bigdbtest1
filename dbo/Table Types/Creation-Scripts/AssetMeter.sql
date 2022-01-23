CREATE TYPE [dbo].[AssetMeter] AS TABLE(
	[BeginReading] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MaximumReading] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[AssetMeterTypeId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
