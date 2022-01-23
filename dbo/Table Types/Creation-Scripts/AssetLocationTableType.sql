CREATE TYPE [dbo].[AssetLocationTableType] AS TABLE(
	[AssetLocationId] [bigint] NULL,
	[TaxBasisType] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[UpfrontTaxMode] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL
)
GO
