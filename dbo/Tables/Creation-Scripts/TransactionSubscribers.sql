SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransactionSubscribers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Subscribed] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NOT NULL,
	[TransactionInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TransactionSubscribers]  WITH CHECK ADD  CONSTRAINT [ETransactionSubscriber_TransactionInstance] FOREIGN KEY([TransactionInstanceId])
REFERENCES [dbo].[TransactionInstances] ([Id])
GO
ALTER TABLE [dbo].[TransactionSubscribers] CHECK CONSTRAINT [ETransactionSubscriber_TransactionInstance]
GO
ALTER TABLE [dbo].[TransactionSubscribers]  WITH CHECK ADD  CONSTRAINT [ETransactionSubscriber_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[TransactionSubscribers] CHECK CONSTRAINT [ETransactionSubscriber_User]
GO
