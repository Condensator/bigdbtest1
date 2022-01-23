SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CollectionWorkLists](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Status] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssignmentMethod] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[PrimaryCollectorId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[CollectionQueueId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RemitToId] [bigint] NULL,
	[BusinessUnitId] [bigint] NULL,
	[FlagAsWorked] [bit] NOT NULL,
	[NextWorkDate] [date] NULL,
	[FlagAsWorkedOn] [datetimeoffset](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [ECollectionWorkList_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[CollectionWorkLists] CHECK CONSTRAINT [ECollectionWorkList_BusinessUnit]
GO
ALTER TABLE [dbo].[CollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [ECollectionWorkList_CollectionQueue] FOREIGN KEY([CollectionQueueId])
REFERENCES [dbo].[CollectionQueues] ([Id])
GO
ALTER TABLE [dbo].[CollectionWorkLists] CHECK CONSTRAINT [ECollectionWorkList_CollectionQueue]
GO
ALTER TABLE [dbo].[CollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [ECollectionWorkList_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[CollectionWorkLists] CHECK CONSTRAINT [ECollectionWorkList_Currency]
GO
ALTER TABLE [dbo].[CollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [ECollectionWorkList_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[CollectionWorkLists] CHECK CONSTRAINT [ECollectionWorkList_Customer]
GO
ALTER TABLE [dbo].[CollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [ECollectionWorkList_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[CollectionWorkLists] CHECK CONSTRAINT [ECollectionWorkList_Portfolio]
GO
ALTER TABLE [dbo].[CollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [ECollectionWorkList_PrimaryCollector] FOREIGN KEY([PrimaryCollectorId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CollectionWorkLists] CHECK CONSTRAINT [ECollectionWorkList_PrimaryCollector]
GO
ALTER TABLE [dbo].[CollectionWorkLists]  WITH CHECK ADD  CONSTRAINT [ECollectionWorkList_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[CollectionWorkLists] CHECK CONSTRAINT [ECollectionWorkList_RemitTo]
GO
