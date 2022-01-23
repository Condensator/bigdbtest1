CREATE TYPE [dbo].[VertexAssetSKUDetail_Extract] AS TABLE(
	[AssetSKUId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetCatalogNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Usage] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
