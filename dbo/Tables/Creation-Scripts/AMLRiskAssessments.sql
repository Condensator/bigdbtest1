SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AMLRiskAssessments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FinalDecision] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntryDate] [date] NULL,
	[Entity] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[InformationOnlyText] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NULL,
	[PartyContactId] [bigint] NULL,
	[PartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AMLRiskAssessments]  WITH CHECK ADD  CONSTRAINT [EAMLRiskAssessment_PartyContact] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[AMLRiskAssessments] CHECK CONSTRAINT [EAMLRiskAssessment_PartyContact]
GO
ALTER TABLE [dbo].[AMLRiskAssessments]  WITH CHECK ADD  CONSTRAINT [EParty_AMLRiskAssessments] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AMLRiskAssessments] CHECK CONSTRAINT [EParty_AMLRiskAssessments]
GO
