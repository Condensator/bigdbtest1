CREATE TYPE [dbo].[SKU] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Quantity] [int] NOT NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsSalesTaxExempt] [bit] NOT NULL,
	[ManufacturerId] [bigint] NULL,
	[MakeId] [bigint] NULL,
	[ModelId] [bigint] NULL,
	[TypeId] [bigint] NOT NULL,
	[AssetCatalogId] [bigint] NULL,
	[AssetCategoryId] [bigint] NULL,
	[ProductId] [bigint] NULL,
	[PricingGroupId] [bigint] NULL,
	[SKUSetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
