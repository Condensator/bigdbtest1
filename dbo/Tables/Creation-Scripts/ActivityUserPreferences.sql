SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityUserPreferences](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsRead] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NOT NULL,
	[ActivityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityUserPreferences]  WITH CHECK ADD  CONSTRAINT [EActivity_ActivityUserPreferences] FOREIGN KEY([ActivityId])
REFERENCES [dbo].[Activities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityUserPreferences] CHECK CONSTRAINT [EActivity_ActivityUserPreferences]
GO
ALTER TABLE [dbo].[ActivityUserPreferences]  WITH CHECK ADD  CONSTRAINT [EActivityUserPreference_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ActivityUserPreferences] CHECK CONSTRAINT [EActivityUserPreference_User]
GO
