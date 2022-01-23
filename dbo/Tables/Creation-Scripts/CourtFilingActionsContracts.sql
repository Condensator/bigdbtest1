SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CourtFilingActionsContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PartyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Role] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeletedRecord] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[PartyId] [bigint] NULL,
	[CourtFilingActionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CourtFilingActionsContracts]  WITH CHECK ADD  CONSTRAINT [ECourtFilingAction_CourtFilingActionsContracts] FOREIGN KEY([CourtFilingActionId])
REFERENCES [dbo].[CourtFilingActions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CourtFilingActionsContracts] CHECK CONSTRAINT [ECourtFilingAction_CourtFilingActionsContracts]
GO
ALTER TABLE [dbo].[CourtFilingActionsContracts]  WITH CHECK ADD  CONSTRAINT [ECourtFilingActionsContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[CourtFilingActionsContracts] CHECK CONSTRAINT [ECourtFilingActionsContract_Contract]
GO
ALTER TABLE [dbo].[CourtFilingActionsContracts]  WITH CHECK ADD  CONSTRAINT [ECourtFilingActionsContract_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[CourtFilingActionsContracts] CHECK CONSTRAINT [ECourtFilingActionsContract_Party]
GO
