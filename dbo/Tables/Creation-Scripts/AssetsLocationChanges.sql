SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetsLocationChanges](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[MoveChildAssets] [bit] NOT NULL,
	[EffectiveFromDate] [date] NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[UpfrontTaxMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[LocationChangeSourceType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[VendorComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LocationId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[VendorId] [bigint] NULL,
	[NewLocationId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[MigrationId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetsLocationChanges]  WITH CHECK ADD  CONSTRAINT [EAssetsLocationChange_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[AssetsLocationChanges] CHECK CONSTRAINT [EAssetsLocationChange_BusinessUnit]
GO
ALTER TABLE [dbo].[AssetsLocationChanges]  WITH CHECK ADD  CONSTRAINT [EAssetsLocationChange_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[AssetsLocationChanges] CHECK CONSTRAINT [EAssetsLocationChange_Location]
GO
ALTER TABLE [dbo].[AssetsLocationChanges]  WITH CHECK ADD  CONSTRAINT [EAssetsLocationChange_NewLocation] FOREIGN KEY([NewLocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[AssetsLocationChanges] CHECK CONSTRAINT [EAssetsLocationChange_NewLocation]
GO
ALTER TABLE [dbo].[AssetsLocationChanges]  WITH CHECK ADD  CONSTRAINT [EAssetsLocationChange_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[AssetsLocationChanges] CHECK CONSTRAINT [EAssetsLocationChange_Vendor]
GO
