SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserSelectionParams](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[UserExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[UserGroupExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NULL,
	[UserGroupId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UserSelectionParams]  WITH CHECK ADD  CONSTRAINT [EUserSelectionParam_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[UserSelectionParams] CHECK CONSTRAINT [EUserSelectionParam_User]
GO
ALTER TABLE [dbo].[UserSelectionParams]  WITH CHECK ADD  CONSTRAINT [EUserSelectionParam_UserGroup] FOREIGN KEY([UserGroupId])
REFERENCES [dbo].[UserGroups] ([Id])
GO
ALTER TABLE [dbo].[UserSelectionParams] CHECK CONSTRAINT [EUserSelectionParam_UserGroup]
GO
