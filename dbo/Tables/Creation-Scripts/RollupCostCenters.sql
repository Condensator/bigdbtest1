SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RollupCostCenters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CostCenter] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[InstrumentTypeId] [bigint] NOT NULL,
	[GLEntryItemId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RollupCostCenters]  WITH CHECK ADD  CONSTRAINT [ERollupCostCenter_GLEntryItem] FOREIGN KEY([GLEntryItemId])
REFERENCES [dbo].[GLEntryItems] ([Id])
GO
ALTER TABLE [dbo].[RollupCostCenters] CHECK CONSTRAINT [ERollupCostCenter_GLEntryItem]
GO
ALTER TABLE [dbo].[RollupCostCenters]  WITH CHECK ADD  CONSTRAINT [ERollupCostCenter_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[RollupCostCenters] CHECK CONSTRAINT [ERollupCostCenter_InstrumentType]
GO
ALTER TABLE [dbo].[RollupCostCenters]  WITH CHECK ADD  CONSTRAINT [ERollupCostCenter_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[RollupCostCenters] CHECK CONSTRAINT [ERollupCostCenter_LegalEntity]
GO
