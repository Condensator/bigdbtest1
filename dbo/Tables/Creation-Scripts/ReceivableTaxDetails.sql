SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableTaxDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[UpfrontTaxMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Revenue_Amount] [decimal](16, 2) NOT NULL,
	[Revenue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FairMarketValue_Amount] [decimal](16, 2) NOT NULL,
	[FairMarketValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxAreaId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[ManuallyAssessed] [bit] NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetLocationId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[ReceivableTaxId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[UpfrontTaxSundryId] [bigint] NULL,
	[TaxCodeId] [bigint] NULL,
	[UpfrontPayableFactor] [decimal](10, 6) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableTax_ReceivableTaxDetails] FOREIGN KEY([ReceivableTaxId])
REFERENCES [dbo].[ReceivableTaxes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableTaxDetails] CHECK CONSTRAINT [EReceivableTax_ReceivableTaxDetails]
GO
ALTER TABLE [dbo].[ReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxDetails] CHECK CONSTRAINT [EReceivableTaxDetail_Asset]
GO
ALTER TABLE [dbo].[ReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxDetail_AssetLocation] FOREIGN KEY([AssetLocationId])
REFERENCES [dbo].[AssetLocations] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxDetails] CHECK CONSTRAINT [EReceivableTaxDetail_AssetLocation]
GO
ALTER TABLE [dbo].[ReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxDetail_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxDetails] CHECK CONSTRAINT [EReceivableTaxDetail_Location]
GO
ALTER TABLE [dbo].[ReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxDetail_ReceivableDetail] FOREIGN KEY([ReceivableDetailId])
REFERENCES [dbo].[ReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxDetails] CHECK CONSTRAINT [EReceivableTaxDetail_ReceivableDetail]
GO
ALTER TABLE [dbo].[ReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxDetail_TaxCode] FOREIGN KEY([TaxCodeId])
REFERENCES [dbo].[TaxCodes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxDetails] CHECK CONSTRAINT [EReceivableTaxDetail_TaxCode]
GO
ALTER TABLE [dbo].[ReceivableTaxDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxDetail_UpfrontTaxSundry] FOREIGN KEY([UpfrontTaxSundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxDetails] CHECK CONSTRAINT [EReceivableTaxDetail_UpfrontTaxSundry]
GO
