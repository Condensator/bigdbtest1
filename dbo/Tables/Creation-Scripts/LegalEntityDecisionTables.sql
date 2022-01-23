SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalEntityDecisionTables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NULL,
	[DecisionTableId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalEntityDecisionTables]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_LegalEntityDecisionTables] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalEntityDecisionTables] CHECK CONSTRAINT [ELegalEntity_LegalEntityDecisionTables]
GO
ALTER TABLE [dbo].[LegalEntityDecisionTables]  WITH CHECK ADD  CONSTRAINT [ELegalEntityDecisionTable_DecisionTable] FOREIGN KEY([DecisionTableId])
REFERENCES [dbo].[DecisionTables] ([Id])
GO
ALTER TABLE [dbo].[LegalEntityDecisionTables] CHECK CONSTRAINT [ELegalEntityDecisionTable_DecisionTable]
GO
