SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityTypePermissions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Condition] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AssignmentType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[Permission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreationAllowed] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsOverridable] [bit] NOT NULL,
	[ConditionFor] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[IsReevaluate] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserSelectionId] [bigint] NOT NULL,
	[ActivityTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityTypePermissions]  WITH CHECK ADD  CONSTRAINT [EActivityType_ActivityTypePermissions] FOREIGN KEY([ActivityTypeId])
REFERENCES [dbo].[ActivityTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityTypePermissions] CHECK CONSTRAINT [EActivityType_ActivityTypePermissions]
GO
ALTER TABLE [dbo].[ActivityTypePermissions]  WITH CHECK ADD  CONSTRAINT [EActivityTypePermission_UserSelection] FOREIGN KEY([UserSelectionId])
REFERENCES [dbo].[UserSelectionParams] ([Id])
GO
ALTER TABLE [dbo].[ActivityTypePermissions] CHECK CONSTRAINT [EActivityTypePermission_UserSelection]
GO
