SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLTemplateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLAccountId] [bigint] NULL,
	[EntryItemId] [bigint] NOT NULL,
	[UserBookId] [bigint] NOT NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLTemplateDetails]  WITH CHECK ADD  CONSTRAINT [EGLTemplate_GLTemplateDetails] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GLTemplateDetails] CHECK CONSTRAINT [EGLTemplate_GLTemplateDetails]
GO
ALTER TABLE [dbo].[GLTemplateDetails]  WITH CHECK ADD  CONSTRAINT [EGLTemplateDetail_EntryItem] FOREIGN KEY([EntryItemId])
REFERENCES [dbo].[GLEntryItems] ([Id])
GO
ALTER TABLE [dbo].[GLTemplateDetails] CHECK CONSTRAINT [EGLTemplateDetail_EntryItem]
GO
ALTER TABLE [dbo].[GLTemplateDetails]  WITH CHECK ADD  CONSTRAINT [EGLTemplateDetail_GLAccount] FOREIGN KEY([GLAccountId])
REFERENCES [dbo].[GLAccounts] ([Id])
GO
ALTER TABLE [dbo].[GLTemplateDetails] CHECK CONSTRAINT [EGLTemplateDetail_GLAccount]
GO
ALTER TABLE [dbo].[GLTemplateDetails]  WITH CHECK ADD  CONSTRAINT [EGLTemplateDetail_UserBook] FOREIGN KEY([UserBookId])
REFERENCES [dbo].[GLUserBooks] ([Id])
GO
ALTER TABLE [dbo].[GLTemplateDetails] CHECK CONSTRAINT [EGLTemplateDetail_UserBook]
GO
