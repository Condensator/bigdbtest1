SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LienCollaterals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsAssigned] [bit] NOT NULL,
	[IsRemoved] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[LienFilingId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsSerializedAsset] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LienCollaterals]  WITH CHECK ADD  CONSTRAINT [ELienCollateral_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[LienCollaterals] CHECK CONSTRAINT [ELienCollateral_Asset]
GO
ALTER TABLE [dbo].[LienCollaterals]  WITH CHECK ADD  CONSTRAINT [ELienFiling_LienCollaterals] FOREIGN KEY([LienFilingId])
REFERENCES [dbo].[LienFilings] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LienCollaterals] CHECK CONSTRAINT [ELienFiling_LienCollaterals]
GO
