SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EuroStandardCoEfficients](
	[PermissibleMassFrom] [decimal](16, 2) NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PermissibleMassTill] [decimal](16, 2) NOT NULL,
	[CoEfficient] [decimal](16, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[AssetClassCodeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL
)

GO
ALTER TABLE [dbo].[EuroStandardCoEfficients]  WITH CHECK ADD  CONSTRAINT [EEuroStandardCoEfficient_AssetClassCode] FOREIGN KEY([AssetClassCodeId])
REFERENCES [dbo].[AssetClassConfigs] ([Id])
GO
ALTER TABLE [dbo].[EuroStandardCoEfficients] CHECK CONSTRAINT [EEuroStandardCoEfficient_AssetClassCode]
GO
ALTER TABLE [dbo].[EuroStandardCoEfficients]  WITH CHECK ADD  CONSTRAINT [EEuroStandardCoEfficient_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[EuroStandardCoEfficients] CHECK CONSTRAINT [EEuroStandardCoEfficient_LegalEntity]
GO
