SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetTypeAccountingComplianceDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AccountingStandard] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsLeaseComponent] [bit] NOT NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetTypeAccountingComplianceDetails]  WITH CHECK ADD  CONSTRAINT [EAssetType_AssetTypeAccountingComplianceDetails] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetTypeAccountingComplianceDetails] CHECK CONSTRAINT [EAssetType_AssetTypeAccountingComplianceDetails]
GO
