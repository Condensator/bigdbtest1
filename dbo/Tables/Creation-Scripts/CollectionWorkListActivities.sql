SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CollectionWorkListActivities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [bigint] NOT NULL,
	[ActivityId] [bigint] NOT NULL,
	[ActivityDate] [date] NOT NULL,
	[CollectionWorkListId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[CollectionWorkListActivities]  WITH CHECK ADD  CONSTRAINT [ECollectionWorkList_CollectionWorkListActivities] FOREIGN KEY([CollectionWorkListId])
REFERENCES [dbo].[CollectionWorkLists] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CollectionWorkListActivities] CHECK CONSTRAINT [ECollectionWorkList_CollectionWorkListActivities]
GO
ALTER TABLE [dbo].[CollectionWorkListActivities]  WITH CHECK ADD  CONSTRAINT [ECollectionWorkListActivity_Activity] FOREIGN KEY([ActivityId])
REFERENCES [dbo].[Activities] ([Id])
GO
ALTER TABLE [dbo].[CollectionWorkListActivities] CHECK CONSTRAINT [ECollectionWorkListActivity_Activity]
GO
