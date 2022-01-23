SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Reason] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[AsOfDate] [date] NOT NULL,
	[AcquisitionDate] [date] NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[FinancialType] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceModule] [nvarchar](22) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceModuleId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NULL,
	[ParentAssetId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[ContractId] [bigint] NULL,
	[AssetId] [bigint] NOT NULL,
	[PropertyTaxReportCodeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsReversed] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetHistories]  WITH CHECK ADD  CONSTRAINT [EAssetHistory_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetHistories] CHECK CONSTRAINT [EAssetHistory_Asset]
GO
ALTER TABLE [dbo].[AssetHistories]  WITH CHECK ADD  CONSTRAINT [EAssetHistory_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[AssetHistories] CHECK CONSTRAINT [EAssetHistory_Contract]
GO
ALTER TABLE [dbo].[AssetHistories]  WITH CHECK ADD  CONSTRAINT [EAssetHistory_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[AssetHistories] CHECK CONSTRAINT [EAssetHistory_Customer]
GO
ALTER TABLE [dbo].[AssetHistories]  WITH CHECK ADD  CONSTRAINT [EAssetHistory_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[AssetHistories] CHECK CONSTRAINT [EAssetHistory_LegalEntity]
GO
ALTER TABLE [dbo].[AssetHistories]  WITH CHECK ADD  CONSTRAINT [EAssetHistory_ParentAsset] FOREIGN KEY([ParentAssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetHistories] CHECK CONSTRAINT [EAssetHistory_ParentAsset]
GO
ALTER TABLE [dbo].[AssetHistories]  WITH CHECK ADD  CONSTRAINT [EAssetHistory_PropertyTaxReportCode] FOREIGN KEY([PropertyTaxReportCodeId])
REFERENCES [dbo].[PropertyTaxReportCodeConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetHistories] CHECK CONSTRAINT [EAssetHistory_PropertyTaxReportCode]
GO
