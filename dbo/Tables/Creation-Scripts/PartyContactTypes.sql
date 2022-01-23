SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PartyContactTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ContactType] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PartyContactId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsForDocumentation] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PartyContactTypes]  WITH CHECK ADD  CONSTRAINT [EPartyContact_PartyContactTypes] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PartyContactTypes] CHECK CONSTRAINT [EPartyContact_PartyContactTypes]
GO
