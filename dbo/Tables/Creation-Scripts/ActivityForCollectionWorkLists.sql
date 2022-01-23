SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityForCollectionWorkLists](
	[SubActivityType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentDate] [date] NULL,
	[PaymentMode] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsCustomerContacted] [bit] NOT NULL,
	[PromiseToPayDate] [date] NULL,
	[ContactReference] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CollectionAgentReference] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SourceUsed] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CheckNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ReferenceInvoiceNumber] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CollectionWorkListId] [bigint] NULL,
	[CollectionAgentId] [bigint] NULL,
	[PersonContactedId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[CommentId] [bigint] NULL,
	[ActivityNote] [nvarchar](4000) COLLATE Latin1_General_CI_AS NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [EActivity_ActivityForCollectionWorkList] FOREIGN KEY([Id])
REFERENCES [dbo].[Activities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists] CHECK CONSTRAINT [EActivity_ActivityForCollectionWorkList]
GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [EActivityForCollectionWorkList_CollectionAgent] FOREIGN KEY([CollectionAgentId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists] CHECK CONSTRAINT [EActivityForCollectionWorkList_CollectionAgent]
GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [EActivityForCollectionWorkList_CollectionWorkList] FOREIGN KEY([CollectionWorkListId])
REFERENCES [dbo].[CollectionWorkLists] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists] CHECK CONSTRAINT [EActivityForCollectionWorkList_CollectionWorkList]
GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [EActivityForCollectionWorkList_Comment] FOREIGN KEY([CommentId])
REFERENCES [dbo].[Comments] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists] CHECK CONSTRAINT [EActivityForCollectionWorkList_Comment]
GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [EActivityForCollectionWorkList_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists] CHECK CONSTRAINT [EActivityForCollectionWorkList_Contract]
GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [EActivityForCollectionWorkList_PersonContacted] FOREIGN KEY([PersonContactedId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCollectionWorkLists] CHECK CONSTRAINT [EActivityForCollectionWorkList_PersonContacted]
GO
