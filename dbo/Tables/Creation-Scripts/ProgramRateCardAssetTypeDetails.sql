SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProgramRateCardAssetTypeDetails](
	[AssetType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ProgramRateCardId] [bigint] NULL,
	[PromotionCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ProgramDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProgramRateCardAssetTypeDetails]  WITH CHECK ADD  CONSTRAINT [EProgramDetail_ProgramRateCardAssetTypeDetails] FOREIGN KEY([ProgramDetailId])
REFERENCES [dbo].[ProgramDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProgramRateCardAssetTypeDetails] CHECK CONSTRAINT [EProgramDetail_ProgramRateCardAssetTypeDetails]
GO
