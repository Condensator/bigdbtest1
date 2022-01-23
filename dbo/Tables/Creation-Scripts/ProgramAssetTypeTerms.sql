SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProgramAssetTypeTerms](
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsDefault] [bit] NOT NULL,
	[Term] [int] NOT NULL,
	[ProgramAssetTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProgramAssetTypeTerms]  WITH CHECK ADD  CONSTRAINT [EProgramAssetType_ProgramAssetTypeTerms] FOREIGN KEY([ProgramAssetTypeId])
REFERENCES [dbo].[ProgramAssetTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProgramAssetTypeTerms] CHECK CONSTRAINT [EProgramAssetType_ProgramAssetTypeTerms]
GO
