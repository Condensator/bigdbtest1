CREATE TYPE [dbo].[AssetRelationshipUpdateTempTable] AS TABLE(
	[AssetId] [bigint] NULL,
	[ParentAssetId] [bigint] NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL
)
GO
