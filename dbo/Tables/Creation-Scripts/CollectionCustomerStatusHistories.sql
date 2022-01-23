SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CollectionCustomerStatusHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssignmentMethod] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssignmentDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[CollectionStatusId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AssignedByUserId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CollectionCustomerStatusHistories]  WITH CHECK ADD  CONSTRAINT [ECollectionCustomerStatusHistory_AssignedByUser] FOREIGN KEY([AssignedByUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CollectionCustomerStatusHistories] CHECK CONSTRAINT [ECollectionCustomerStatusHistory_AssignedByUser]
GO
ALTER TABLE [dbo].[CollectionCustomerStatusHistories]  WITH CHECK ADD  CONSTRAINT [ECollectionCustomerStatusHistory_CollectionStatus] FOREIGN KEY([CollectionStatusId])
REFERENCES [dbo].[CollectionStatus] ([Id])
GO
ALTER TABLE [dbo].[CollectionCustomerStatusHistories] CHECK CONSTRAINT [ECollectionCustomerStatusHistory_CollectionStatus]
GO
ALTER TABLE [dbo].[CollectionCustomerStatusHistories]  WITH CHECK ADD  CONSTRAINT [ECollectionCustomerStatusHistory_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[CollectionCustomerStatusHistories] CHECK CONSTRAINT [ECollectionCustomerStatusHistory_Customer]
GO
