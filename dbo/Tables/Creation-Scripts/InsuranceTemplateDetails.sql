SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InsuranceTemplateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[OwnershipStatus] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InsuranceTemplateId] [bigint] NOT NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InsuranceTemplateDetails]  WITH CHECK ADD  CONSTRAINT [EAssetType_InsuranceTemplateDetails] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[InsuranceTemplateDetails] CHECK CONSTRAINT [EAssetType_InsuranceTemplateDetails]
GO
ALTER TABLE [dbo].[InsuranceTemplateDetails]  WITH CHECK ADD  CONSTRAINT [EInsuranceTemplateDetail_InsuranceTemplate] FOREIGN KEY([InsuranceTemplateId])
REFERENCES [dbo].[InsuranceTemplates] ([Id])
GO
ALTER TABLE [dbo].[InsuranceTemplateDetails] CHECK CONSTRAINT [EInsuranceTemplateDetail_InsuranceTemplate]
GO
