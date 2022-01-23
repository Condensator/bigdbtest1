SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLMatchingEntryItems](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Filter] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MatchingEntryItemId] [bigint] NOT NULL,
	[GLEntryItemId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLMatchingEntryItems]  WITH CHECK ADD  CONSTRAINT [EGLEntryItem_GLMatchingEntryItems] FOREIGN KEY([GLEntryItemId])
REFERENCES [dbo].[GLEntryItems] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GLMatchingEntryItems] CHECK CONSTRAINT [EGLEntryItem_GLMatchingEntryItems]
GO
ALTER TABLE [dbo].[GLMatchingEntryItems]  WITH CHECK ADD  CONSTRAINT [EGLMatchingEntryItem_MatchingEntryItem] FOREIGN KEY([MatchingEntryItemId])
REFERENCES [dbo].[GLEntryItems] ([Id])
GO
ALTER TABLE [dbo].[GLMatchingEntryItems] CHECK CONSTRAINT [EGLMatchingEntryItem_MatchingEntryItem]
GO
