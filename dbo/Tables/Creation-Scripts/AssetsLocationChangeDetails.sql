SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetsLocationChangeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReciprocityAmount_Amount] [decimal](16, 2) NULL,
	[ReciprocityAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LienCredit_Amount] [decimal](16, 2) NULL,
	[LienCredit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsFLStampTaxExempt] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetsLocationChangeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetsLocationChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsLocationChange_AssetsLocationChangeDetails] FOREIGN KEY([AssetsLocationChangeId])
REFERENCES [dbo].[AssetsLocationChanges] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetsLocationChangeDetails] CHECK CONSTRAINT [EAssetsLocationChange_AssetsLocationChangeDetails]
GO
ALTER TABLE [dbo].[AssetsLocationChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsLocationChangeDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetsLocationChangeDetails] CHECK CONSTRAINT [EAssetsLocationChangeDetail_Asset]
GO
