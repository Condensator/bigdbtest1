SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserGroups](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[GroupEmailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DefaultRoleFunctionId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UserGroups]  WITH CHECK ADD  CONSTRAINT [EUserGroup_DefaultRoleFunction] FOREIGN KEY([DefaultRoleFunctionId])
REFERENCES [dbo].[RoleFunctions] ([Id])
GO
ALTER TABLE [dbo].[UserGroups] CHECK CONSTRAINT [EUserGroup_DefaultRoleFunction]
GO
