SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChargeOffAssetDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[NetWritedown_Amount] [decimal](16, 2) NOT NULL,
	[NetWritedown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetInvestmentWithBlended_Amount] [decimal](16, 2) NOT NULL,
	[NetInvestmentWithBlended_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[ChargeOffId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ChargeOffAssetDetails]  WITH CHECK ADD  CONSTRAINT [EChargeOff_ChargeOffAssetDetails] FOREIGN KEY([ChargeOffId])
REFERENCES [dbo].[ChargeOffs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ChargeOffAssetDetails] CHECK CONSTRAINT [EChargeOff_ChargeOffAssetDetails]
GO
ALTER TABLE [dbo].[ChargeOffAssetDetails]  WITH CHECK ADD  CONSTRAINT [EChargeOffAssetDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[ChargeOffAssetDetails] CHECK CONSTRAINT [EChargeOffAssetDetail_Asset]
GO
