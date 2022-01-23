CREATE TYPE [dbo].[CPIAssetMeterType] AS TABLE(
	[OldReading] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NewReading] [int] NOT NULL,
	[AssetMeterTypeId] [bigint] NOT NULL,
	[CPIAssetMeterId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
