SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetLocations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveFromDate] [date] NOT NULL,
	[IsCurrent] [bit] NOT NULL,
	[UpfrontTaxMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[IsFLStampTaxExempt] [bit] NOT NULL,
	[ReciprocityAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReciprocityAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LienCredit_Amount] [decimal](16, 2) NOT NULL,
	[LienCredit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LocationId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[UpfrontTaxAssessedInLegacySystem] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetLocations]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetLocations] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetLocations] CHECK CONSTRAINT [EAsset_AssetLocations]
GO
ALTER TABLE [dbo].[AssetLocations]  WITH CHECK ADD  CONSTRAINT [EAssetLocation_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[AssetLocations] CHECK CONSTRAINT [EAssetLocation_Location]
GO
