SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CourtFilingActions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LegalReliefType] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[LegalAction] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActionName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActionType] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActionStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[FilingDate] [date] NULL,
	[DeadlineDate] [date] NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsDeletedRecord] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RelatedLegalActionId] [bigint] NULL,
	[CourtFilingId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CourtFilingActions]  WITH CHECK ADD  CONSTRAINT [ECourtFiling_CourtFilingActions] FOREIGN KEY([CourtFilingId])
REFERENCES [dbo].[CourtFilings] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CourtFilingActions] CHECK CONSTRAINT [ECourtFiling_CourtFilingActions]
GO
ALTER TABLE [dbo].[CourtFilingActions]  WITH CHECK ADD  CONSTRAINT [ECourtFilingAction_RelatedLegalAction] FOREIGN KEY([RelatedLegalActionId])
REFERENCES [dbo].[CourtFilingActions] ([Id])
GO
ALTER TABLE [dbo].[CourtFilingActions] CHECK CONSTRAINT [ECourtFilingAction_RelatedLegalAction]
GO
