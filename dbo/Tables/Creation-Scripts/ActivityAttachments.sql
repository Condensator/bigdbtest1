SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AttachmentId] [bigint] NOT NULL,
	[ActivityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityAttachments]  WITH CHECK ADD  CONSTRAINT [EActivity_ActivityAttachments] FOREIGN KEY([ActivityId])
REFERENCES [dbo].[Activities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityAttachments] CHECK CONSTRAINT [EActivity_ActivityAttachments]
GO
ALTER TABLE [dbo].[ActivityAttachments]  WITH CHECK ADD  CONSTRAINT [EActivityAttachment_Attachment] FOREIGN KEY([AttachmentId])
REFERENCES [dbo].[Attachments] ([Id])
GO
ALTER TABLE [dbo].[ActivityAttachments] CHECK CONSTRAINT [EActivityAttachment_Attachment]
GO
