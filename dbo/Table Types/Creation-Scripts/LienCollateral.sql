CREATE TYPE [dbo].[LienCollateral] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsAssigned] [bit] NOT NULL,
	[IsRemoved] [bit] NOT NULL,
	[IsSerializedAsset] [bit] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[LienFilingId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
