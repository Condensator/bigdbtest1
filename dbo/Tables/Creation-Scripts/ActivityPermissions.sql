SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityPermissions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Permission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActivityTypePermissionId] [bigint] NULL,
	[UserId] [bigint] NOT NULL,
	[ActivityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityPermissions]  WITH CHECK ADD  CONSTRAINT [EActivity_ActivityPermissions] FOREIGN KEY([ActivityId])
REFERENCES [dbo].[Activities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityPermissions] CHECK CONSTRAINT [EActivity_ActivityPermissions]
GO
ALTER TABLE [dbo].[ActivityPermissions]  WITH CHECK ADD  CONSTRAINT [EActivityPermission_ActivityTypePermission] FOREIGN KEY([ActivityTypePermissionId])
REFERENCES [dbo].[ActivityTypePermissions] ([Id])
GO
ALTER TABLE [dbo].[ActivityPermissions] CHECK CONSTRAINT [EActivityPermission_ActivityTypePermission]
GO
ALTER TABLE [dbo].[ActivityPermissions]  WITH CHECK ADD  CONSTRAINT [EActivityPermission_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ActivityPermissions] CHECK CONSTRAINT [EActivityPermission_User]
GO
