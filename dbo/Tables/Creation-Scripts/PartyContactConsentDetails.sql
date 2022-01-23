SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PartyContactConsentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ConsentDetailId] [bigint] NOT NULL,
	[PartyContactId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PartyContactConsentDetails]  WITH CHECK ADD  CONSTRAINT [EPartyContact_PartyContactConsentDetails] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PartyContactConsentDetails] CHECK CONSTRAINT [EPartyContact_PartyContactConsentDetails]
GO
ALTER TABLE [dbo].[PartyContactConsentDetails]  WITH CHECK ADD  CONSTRAINT [EPartyContactConsentDetail_ConsentDetail] FOREIGN KEY([ConsentDetailId])
REFERENCES [dbo].[ConsentDetails] ([Id])
GO
ALTER TABLE [dbo].[PartyContactConsentDetails] CHECK CONSTRAINT [EPartyContactConsentDetail_ConsentDetail]
GO
