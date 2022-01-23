SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MaturityMonitorFMVAssetDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsNegotiable] [bit] NOT NULL,
	[GeneralDescription] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[OriginalCost_Amount] [decimal](16, 2) NOT NULL,
	[OriginalCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Residual_Amount] [decimal](16, 2) NULL,
	[Residual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FMVMaturity_Amount] [decimal](16, 2) NULL,
	[FMVMaturity_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FMVMDate] [date] NULL,
	[OLVPresent_Amount] [decimal](16, 2) NULL,
	[OLVPresent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[OLVPresentDate] [date] NULL,
	[PurchasePrice_Amount] [decimal](16, 2) NULL,
	[PurchasePrice_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PurchasePriceDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[MaturityMonitorId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[MaturityMonitorFMVAssetDetails]  WITH CHECK ADD  CONSTRAINT [EMaturityMonitor_MaturityMonitorFMVAssetDetails] FOREIGN KEY([MaturityMonitorId])
REFERENCES [dbo].[MaturityMonitors] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[MaturityMonitorFMVAssetDetails] CHECK CONSTRAINT [EMaturityMonitor_MaturityMonitorFMVAssetDetails]
GO
ALTER TABLE [dbo].[MaturityMonitorFMVAssetDetails]  WITH CHECK ADD  CONSTRAINT [EMaturityMonitorFMVAssetDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[MaturityMonitorFMVAssetDetails] CHECK CONSTRAINT [EMaturityMonitorFMVAssetDetail_Asset]
GO
