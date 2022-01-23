SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OFACHits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[HitValue] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[DecisionTime] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DecisionByUserId] [bigint] NULL,
	[OFACRequestId] [bigint] NULL,
	[PartyId] [bigint] NULL,
	[PartyContactId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OFACHits]  WITH CHECK ADD  CONSTRAINT [EOFACHit_DecisionByUser] FOREIGN KEY([DecisionByUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[OFACHits] CHECK CONSTRAINT [EOFACHit_DecisionByUser]
GO
ALTER TABLE [dbo].[OFACHits]  WITH CHECK ADD  CONSTRAINT [EOFACHit_OFACRequest] FOREIGN KEY([OFACRequestId])
REFERENCES [dbo].[OFACRequests] ([Id])
GO
ALTER TABLE [dbo].[OFACHits] CHECK CONSTRAINT [EOFACHit_OFACRequest]
GO
ALTER TABLE [dbo].[OFACHits]  WITH CHECK ADD  CONSTRAINT [EOFACHit_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[OFACHits] CHECK CONSTRAINT [EOFACHit_Party]
GO
ALTER TABLE [dbo].[OFACHits]  WITH CHECK ADD  CONSTRAINT [EOFACHit_PartyContact] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[OFACHits] CHECK CONSTRAINT [EOFACHit_PartyContact]
GO
