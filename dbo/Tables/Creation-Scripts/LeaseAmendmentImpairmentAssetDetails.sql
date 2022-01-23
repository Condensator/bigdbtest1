SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseAmendmentImpairmentAssetDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ResidualImpairmentAmount_Amount] [decimal](16, 2) NULL,
	[ResidualImpairmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NBVImpairmentAmount_Amount] [decimal](16, 2) NULL,
	[NBVImpairmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[LeaseAmendmentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PVOfAsset_Amount] [decimal](16, 2) NULL,
	[PVOfAsset_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
	[PreRestructureBookedResidualAmount_Amount] [decimal](16, 2) NULL,
	[PreRestructureBookedResidualAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PostRestructureBookedResidualAmount_Amount] [decimal](16, 2) NULL,
	[PostRestructureBookedResidualAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseAmendmentImpairmentAssetDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_LeaseAmendmentImpairmentAssetDetails] FOREIGN KEY([LeaseAmendmentId])
REFERENCES [dbo].[LeaseAmendments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseAmendmentImpairmentAssetDetails] CHECK CONSTRAINT [ELeaseAmendment_LeaseAmendmentImpairmentAssetDetails]
GO
ALTER TABLE [dbo].[LeaseAmendmentImpairmentAssetDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendmentImpairmentAssetDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendmentImpairmentAssetDetails] CHECK CONSTRAINT [ELeaseAmendmentImpairmentAssetDetail_Asset]
GO
ALTER TABLE [dbo].[LeaseAmendmentImpairmentAssetDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendmentImpairmentAssetDetail_BookDepreciationTemplate] FOREIGN KEY([BookDepreciationTemplateId])
REFERENCES [dbo].[BookDepreciationTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendmentImpairmentAssetDetails] CHECK CONSTRAINT [ELeaseAmendmentImpairmentAssetDetail_BookDepreciationTemplate]
GO
