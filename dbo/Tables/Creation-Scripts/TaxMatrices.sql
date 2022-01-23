SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxMatrices](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxLevel] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TaxCodeId] [bigint] NOT NULL,
	[TaxReceivableTypeId] [bigint] NULL,
	[PayableTypeId] [bigint] NULL,
	[TaxAssetTypeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BuyerCountryId] [bigint] NULL,
	[SellerCountryId] [bigint] NULL,
	[BuyerStateId] [bigint] NULL,
	[SellerStateId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxMatrices]  WITH CHECK ADD  CONSTRAINT [ETaxMatrix_BuyerCountry] FOREIGN KEY([BuyerCountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[TaxMatrices] CHECK CONSTRAINT [ETaxMatrix_BuyerCountry]
GO
ALTER TABLE [dbo].[TaxMatrices]  WITH CHECK ADD  CONSTRAINT [ETaxMatrix_BuyerState] FOREIGN KEY([BuyerStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[TaxMatrices] CHECK CONSTRAINT [ETaxMatrix_BuyerState]
GO
ALTER TABLE [dbo].[TaxMatrices]  WITH CHECK ADD  CONSTRAINT [ETaxMatrix_PayableType] FOREIGN KEY([PayableTypeId])
REFERENCES [dbo].[PayableTypes] ([Id])
GO
ALTER TABLE [dbo].[TaxMatrices] CHECK CONSTRAINT [ETaxMatrix_PayableType]
GO
ALTER TABLE [dbo].[TaxMatrices]  WITH CHECK ADD  CONSTRAINT [ETaxMatrix_SellerCountry] FOREIGN KEY([SellerCountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[TaxMatrices] CHECK CONSTRAINT [ETaxMatrix_SellerCountry]
GO
ALTER TABLE [dbo].[TaxMatrices]  WITH CHECK ADD  CONSTRAINT [ETaxMatrix_SellerState] FOREIGN KEY([SellerStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[TaxMatrices] CHECK CONSTRAINT [ETaxMatrix_SellerState]
GO
ALTER TABLE [dbo].[TaxMatrices]  WITH CHECK ADD  CONSTRAINT [ETaxMatrix_TaxAssetType] FOREIGN KEY([TaxAssetTypeId])
REFERENCES [dbo].[TaxAssetTypes] ([Id])
GO
ALTER TABLE [dbo].[TaxMatrices] CHECK CONSTRAINT [ETaxMatrix_TaxAssetType]
GO
ALTER TABLE [dbo].[TaxMatrices]  WITH CHECK ADD  CONSTRAINT [ETaxMatrix_TaxCode] FOREIGN KEY([TaxCodeId])
REFERENCES [dbo].[TaxCodes] ([Id])
GO
ALTER TABLE [dbo].[TaxMatrices] CHECK CONSTRAINT [ETaxMatrix_TaxCode]
GO
ALTER TABLE [dbo].[TaxMatrices]  WITH CHECK ADD  CONSTRAINT [ETaxMatrix_TaxReceivableType] FOREIGN KEY([TaxReceivableTypeId])
REFERENCES [dbo].[TaxReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[TaxMatrices] CHECK CONSTRAINT [ETaxMatrix_TaxReceivableType]
GO
