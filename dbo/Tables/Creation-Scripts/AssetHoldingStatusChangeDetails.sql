SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetHoldingStatusChangeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetHoldingStatusChangeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[NewInstrumentTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[NewLineofBusinessId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetHoldingStatusChange_AssetHoldingStatusChangeDetails] FOREIGN KEY([AssetHoldingStatusChangeId])
REFERENCES [dbo].[AssetHoldingStatusChanges] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails] CHECK CONSTRAINT [EAssetHoldingStatusChange_AssetHoldingStatusChangeDetails]
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetHoldingStatusChangeDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails] CHECK CONSTRAINT [EAssetHoldingStatusChangeDetail_Asset]
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetHoldingStatusChangeDetail_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails] CHECK CONSTRAINT [EAssetHoldingStatusChangeDetail_CostCenter]
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetHoldingStatusChangeDetail_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails] CHECK CONSTRAINT [EAssetHoldingStatusChangeDetail_InstrumentType]
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetHoldingStatusChangeDetail_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails] CHECK CONSTRAINT [EAssetHoldingStatusChangeDetail_LineofBusiness]
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetHoldingStatusChangeDetail_NewInstrumentType] FOREIGN KEY([NewInstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails] CHECK CONSTRAINT [EAssetHoldingStatusChangeDetail_NewInstrumentType]
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetHoldingStatusChangeDetail_NewLineofBusiness] FOREIGN KEY([NewLineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[AssetHoldingStatusChangeDetails] CHECK CONSTRAINT [EAssetHoldingStatusChangeDetail_NewLineofBusiness]
GO
