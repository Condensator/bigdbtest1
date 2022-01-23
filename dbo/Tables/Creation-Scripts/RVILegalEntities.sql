SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RVILegalEntities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[BlendedItemCodeId] [bigint] NOT NULL,
	[RVIParameterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RVILegalEntities]  WITH CHECK ADD  CONSTRAINT [ERVILegalEntity_BlendedItemCode] FOREIGN KEY([BlendedItemCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[RVILegalEntities] CHECK CONSTRAINT [ERVILegalEntity_BlendedItemCode]
GO
ALTER TABLE [dbo].[RVILegalEntities]  WITH CHECK ADD  CONSTRAINT [ERVILegalEntity_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[RVILegalEntities] CHECK CONSTRAINT [ERVILegalEntity_LegalEntity]
GO
ALTER TABLE [dbo].[RVILegalEntities]  WITH CHECK ADD  CONSTRAINT [ERVIParameter_RVILegalEntities] FOREIGN KEY([RVIParameterId])
REFERENCES [dbo].[RVIParameters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RVILegalEntities] CHECK CONSTRAINT [ERVIParameter_RVILegalEntities]
GO
