SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PPTExtractIncludedAssetDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[NumberOfAssets] [bigint] NULL,
	[TotalPPTBasis_Amount] [decimal](16, 2) NOT NULL,
	[TotalPPTBasis_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NumberOfAssetsToTransfer] [bigint] NULL,
	[TotalPPTBasisToTransfer_Amount] [decimal](16, 2) NOT NULL,
	[TotalPPTBasisToTransfer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExportFile] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[PPTExtractDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PPTExtractIncludedAssetDetails]  WITH CHECK ADD  CONSTRAINT [EPPTExtractDetail_PPTExtractIncludedAssetDetails] FOREIGN KEY([PPTExtractDetailId])
REFERENCES [dbo].[PPTExtractDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PPTExtractIncludedAssetDetails] CHECK CONSTRAINT [EPPTExtractDetail_PPTExtractIncludedAssetDetails]
GO
ALTER TABLE [dbo].[PPTExtractIncludedAssetDetails]  WITH CHECK ADD  CONSTRAINT [EPPTExtractIncludedAssetDetail_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[PPTExtractIncludedAssetDetails] CHECK CONSTRAINT [EPPTExtractIncludedAssetDetail_LegalEntity]
GO
ALTER TABLE [dbo].[PPTExtractIncludedAssetDetails]  WITH CHECK ADD  CONSTRAINT [EPPTExtractIncludedAssetDetail_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[PPTExtractIncludedAssetDetails] CHECK CONSTRAINT [EPPTExtractIncludedAssetDetail_State]
GO
