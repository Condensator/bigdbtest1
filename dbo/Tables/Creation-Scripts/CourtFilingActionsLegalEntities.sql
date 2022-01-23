SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CourtFilingActionsLegalEntities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Role] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeletedRecord] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NULL,
	[CourtFilingActionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CourtFilingActionsLegalEntities]  WITH CHECK ADD  CONSTRAINT [ECourtFilingAction_CourtFilingActionsLegalEntities] FOREIGN KEY([CourtFilingActionId])
REFERENCES [dbo].[CourtFilingActions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CourtFilingActionsLegalEntities] CHECK CONSTRAINT [ECourtFilingAction_CourtFilingActionsLegalEntities]
GO
ALTER TABLE [dbo].[CourtFilingActionsLegalEntities]  WITH CHECK ADD  CONSTRAINT [ECourtFilingActionsLegalEntity_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[CourtFilingActionsLegalEntities] CHECK CONSTRAINT [ECourtFilingActionsLegalEntity_LegalEntity]
GO
