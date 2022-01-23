SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableTaxReversalDetails](
	[Id] [bigint] NOT NULL,
	[IsExemptAtAsset] [bit] NOT NULL,
	[IsExemptAtLease] [bit] NOT NULL,
	[IsExemptAtSundry] [bit] NOT NULL,
	[Company] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Product] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ContractType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[LeaseType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LeaseTerm] [decimal](18, 8) NULL,
	[TitleTransferCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TransactionCode] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[AmountBilledToDate] [decimal](16, 2) NULL,
	[AssetId] [bigint] NULL,
	[AssetLocationId] [bigint] NULL,
	[ToStateName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FromStateName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SalesTaxRemittanceResponsibility] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsCapitalizeUpfrontSalesTax] [bit] NOT NULL,
	[UpfrontTaxAssessedInLegacySystem] [bit] NOT NULL,
	[BusCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableTaxReversalDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxDetail_ReceivableTaxReversalDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[ReceivableTaxDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableTaxReversalDetails] CHECK CONSTRAINT [EReceivableTaxDetail_ReceivableTaxReversalDetail]
GO
ALTER TABLE [dbo].[ReceivableTaxReversalDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxReversalDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxReversalDetails] CHECK CONSTRAINT [EReceivableTaxReversalDetail_Asset]
GO
ALTER TABLE [dbo].[ReceivableTaxReversalDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxReversalDetail_AssetLocation] FOREIGN KEY([AssetLocationId])
REFERENCES [dbo].[AssetLocations] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxReversalDetails] CHECK CONSTRAINT [EReceivableTaxReversalDetail_AssetLocation]
GO
