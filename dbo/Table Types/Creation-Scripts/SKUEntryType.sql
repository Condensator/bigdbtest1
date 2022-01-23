CREATE TYPE [dbo].[SKUEntryType] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Alias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SerialNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Quantity] [int] NOT NULL,
	[IsLeaseComponent] [bit] NOT NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[ManufacturerId] [bigint] NULL,
	[MakeId] [bigint] NULL,
	[ModelId] [bigint] NULL,
	[TypeId] [bigint] NOT NULL,
	[PricingGroupId] [bigint] NULL,
	[AssetCatalogId] [bigint] NULL,
	[AssetCategoryId] [bigint] NULL,
	[ProductId] [bigint] NULL,
	[AssetAlias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsSalesTaxExempt] [bit] NOT NULL
)
GO
