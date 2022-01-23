SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PersonalGuarantorCIPHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SocialSecurityNumber] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[CIPDocumentSourceForName] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[CIPDocumentSourceForAddress] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[CIPDocumentSourceForTaxIdOrSSN] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NULL,
	[PartyContactId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CIPDocumentSourceNameId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PersonalGuarantorCIPHistories]  WITH CHECK ADD  CONSTRAINT [EPartyContact_PersonalGuarantorCIPHistories] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PersonalGuarantorCIPHistories] CHECK CONSTRAINT [EPartyContact_PersonalGuarantorCIPHistories]
GO
ALTER TABLE [dbo].[PersonalGuarantorCIPHistories]  WITH CHECK ADD  CONSTRAINT [EPersonalGuarantorCIPHistory_CIPDocumentSourceName] FOREIGN KEY([CIPDocumentSourceNameId])
REFERENCES [dbo].[CIPDocumentSourceConfigs] ([Id])
GO
ALTER TABLE [dbo].[PersonalGuarantorCIPHistories] CHECK CONSTRAINT [EPersonalGuarantorCIPHistory_CIPDocumentSourceName]
GO
ALTER TABLE [dbo].[PersonalGuarantorCIPHistories]  WITH CHECK ADD  CONSTRAINT [EPersonalGuarantorCIPHistory_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[PersonalGuarantorCIPHistories] CHECK CONSTRAINT [EPersonalGuarantorCIPHistory_State]
GO
