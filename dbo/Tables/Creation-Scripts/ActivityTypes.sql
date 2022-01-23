SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Duration] [bigint] NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[AllowDuplicate] [bit] NOT NULL,
	[DefaultPermission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreationAllowed] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Category] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[IsWorkflowEnabled] [bit] NOT NULL,
	[IsTrueTask] [bit] NOT NULL,
	[TransactionTobeInitiatedId] [bigint] NULL,
	[Type] [nvarchar](29) COLLATE Latin1_General_CI_AS NULL,
	[IsViewableInCustomerSummary] [bit] NOT NULL,
	[DefaultUserId] [bigint] NULL,
	[DefaultUserGroupId] [bigint] NULL,
	[PortfolioId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityTypes]  WITH CHECK ADD  CONSTRAINT [EActivityType_DefaultUser] FOREIGN KEY([DefaultUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ActivityTypes] CHECK CONSTRAINT [EActivityType_DefaultUser]
GO
ALTER TABLE [dbo].[ActivityTypes]  WITH CHECK ADD  CONSTRAINT [EActivityType_DefaultUserGroup] FOREIGN KEY([DefaultUserGroupId])
REFERENCES [dbo].[UserGroups] ([Id])
GO
ALTER TABLE [dbo].[ActivityTypes] CHECK CONSTRAINT [EActivityType_DefaultUserGroup]
GO
ALTER TABLE [dbo].[ActivityTypes]  WITH CHECK ADD  CONSTRAINT [EActivityType_EntityType] FOREIGN KEY([EntityTypeId])
REFERENCES [dbo].[ActivityEntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[ActivityTypes] CHECK CONSTRAINT [EActivityType_EntityType]
GO
ALTER TABLE [dbo].[ActivityTypes]  WITH CHECK ADD  CONSTRAINT [EActivityType_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[ActivityTypes] CHECK CONSTRAINT [EActivityType_Portfolio]
GO
ALTER TABLE [dbo].[ActivityTypes]  WITH CHECK ADD  CONSTRAINT [EActivityType_TransactionTobeInitiated] FOREIGN KEY([TransactionTobeInitiatedId])
REFERENCES [dbo].[ActivityTransactionConfigs] ([Id])
GO
ALTER TABLE [dbo].[ActivityTypes] CHECK CONSTRAINT [EActivityType_TransactionTobeInitiated]
GO
