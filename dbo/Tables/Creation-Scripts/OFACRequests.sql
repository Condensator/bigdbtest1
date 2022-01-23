SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OFACRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[RequestDate] [date] NULL,
	[ResponseDate] [date] NULL,
	[ResponseType] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[RequestXml] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ResponseXml] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PartyId] [bigint] NULL,
	[PartyContactId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OFACRequests]  WITH CHECK ADD  CONSTRAINT [EOFACRequest_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[OFACRequests] CHECK CONSTRAINT [EOFACRequest_Party]
GO
ALTER TABLE [dbo].[OFACRequests]  WITH CHECK ADD  CONSTRAINT [EOFACRequest_PartyContact] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[OFACRequests] CHECK CONSTRAINT [EOFACRequest_PartyContact]
GO
