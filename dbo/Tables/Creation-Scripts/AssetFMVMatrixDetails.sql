SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetFMVMatrixDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FromMonth] [int] NULL,
	[ToMonth] [int] NULL,
	[FMVFactor] [decimal](8, 4) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetFMVMatrixId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetFMVMatrixDetails]  WITH CHECK ADD  CONSTRAINT [EAssetFMVMatrix_AssetFMVMatrixDetails] FOREIGN KEY([AssetFMVMatrixId])
REFERENCES [dbo].[AssetFMVMatrices] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetFMVMatrixDetails] CHECK CONSTRAINT [EAssetFMVMatrix_AssetFMVMatrixDetails]
GO
