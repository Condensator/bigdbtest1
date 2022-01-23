SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProgramAssetTypeEOTOptions](
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsDefault] [bit] NOT NULL,
	[EOTOption] [nvarchar](32) COLLATE Latin1_General_CI_AS NOT NULL,
	[ProgramAssetTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProgramAssetTypeEOTOptions]  WITH CHECK ADD  CONSTRAINT [EProgramAssetType_ProgramAssetTypeEOTOptions] FOREIGN KEY([ProgramAssetTypeId])
REFERENCES [dbo].[ProgramAssetTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProgramAssetTypeEOTOptions] CHECK CONSTRAINT [EProgramAssetType_ProgramAssetTypeEOTOptions]
GO
