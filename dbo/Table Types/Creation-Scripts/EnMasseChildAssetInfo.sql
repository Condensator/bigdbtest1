CREATE TYPE [dbo].[EnMasseChildAssetInfo] AS TABLE(
	[ChildAssetId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL
)
GO
