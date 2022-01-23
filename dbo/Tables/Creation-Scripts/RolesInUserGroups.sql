SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RolesInUserGroups](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RoleId] [bigint] NOT NULL,
	[UserGroupId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RolesInUserGroups]  WITH CHECK ADD  CONSTRAINT [ERolesInUserGroup_Role] FOREIGN KEY([RoleId])
REFERENCES [dbo].[Roles] ([Id])
GO
ALTER TABLE [dbo].[RolesInUserGroups] CHECK CONSTRAINT [ERolesInUserGroup_Role]
GO
ALTER TABLE [dbo].[RolesInUserGroups]  WITH CHECK ADD  CONSTRAINT [EUserGroup_RolesInUserGroups] FOREIGN KEY([UserGroupId])
REFERENCES [dbo].[UserGroups] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RolesInUserGroups] CHECK CONSTRAINT [EUserGroup_RolesInUserGroups]
GO
