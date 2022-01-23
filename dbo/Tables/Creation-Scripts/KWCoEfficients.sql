SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[KWCoEfficients](
	[PermissibleMassFrom] [decimal](16, 2) NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PermissibleMassTill] [decimal](16, 2) NOT NULL,
	[KWFrom] [decimal](16, 2) NOT NULL,
	[KWTo] [decimal](16, 2) NOT NULL,
	[CoEfficient] [decimal](16, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL
)

GO
ALTER TABLE [dbo].[KWCoEfficients]  WITH CHECK ADD  CONSTRAINT [EKWCoEfficient_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[KWCoEfficients] CHECK CONSTRAINT [EKWCoEfficient_AssetType]
GO
ALTER TABLE [dbo].[KWCoEfficients]  WITH CHECK ADD  CONSTRAINT [EKWCoEfficient_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[KWCoEfficients] CHECK CONSTRAINT [EKWCoEfficient_LegalEntity]
GO
