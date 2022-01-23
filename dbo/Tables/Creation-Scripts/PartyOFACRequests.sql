SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PartyOFACRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OFACRequestId] [bigint] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PartyOFACRequests]  WITH CHECK ADD  CONSTRAINT [EParty_PartyOFACRequests] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PartyOFACRequests] CHECK CONSTRAINT [EParty_PartyOFACRequests]
GO
ALTER TABLE [dbo].[PartyOFACRequests]  WITH CHECK ADD  CONSTRAINT [EPartyOFACRequest_OFACRequest] FOREIGN KEY([OFACRequestId])
REFERENCES [dbo].[OFACRequests] ([Id])
GO
ALTER TABLE [dbo].[PartyOFACRequests] CHECK CONSTRAINT [EPartyOFACRequest_OFACRequest]
GO
