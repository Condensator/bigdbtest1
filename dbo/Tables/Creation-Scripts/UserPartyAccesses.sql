SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserPartyAccesses](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PartyId] [bigint] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ContractId] [bigint] NULL,
	[BillToId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UserPartyAccesses]  WITH CHECK ADD  CONSTRAINT [EUser_UserPartyAccesses] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserPartyAccesses] CHECK CONSTRAINT [EUser_UserPartyAccesses]
GO
ALTER TABLE [dbo].[UserPartyAccesses]  WITH CHECK ADD  CONSTRAINT [EUserPartyAccess_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[UserPartyAccesses] CHECK CONSTRAINT [EUserPartyAccess_BillTo]
GO
ALTER TABLE [dbo].[UserPartyAccesses]  WITH CHECK ADD  CONSTRAINT [EUserPartyAccess_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[UserPartyAccesses] CHECK CONSTRAINT [EUserPartyAccess_Contract]
GO
ALTER TABLE [dbo].[UserPartyAccesses]  WITH CHECK ADD  CONSTRAINT [EUserPartyAccess_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[UserPartyAccesses] CHECK CONSTRAINT [EUserPartyAccess_Party]
GO
