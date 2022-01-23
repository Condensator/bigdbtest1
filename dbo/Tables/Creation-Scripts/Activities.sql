SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Activities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Solution] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[FollowUpDate] [datetimeoffset](7) NULL,
	[TargetCompletionDate] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[EntityId] [bigint] NULL,
	[EntityNaturalId] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[DefaultPermission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OwnerId] [bigint] NULL,
	[ActivityTypeId] [bigint] NULL,
	[StatusId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DocumentListId] [bigint] NULL,
	[CreatedDate] [date] NOT NULL,
	[CompletionDate] [datetimeoffset](7) NULL,
	[IsFollowUpRequired] [bit] NOT NULL,
	[InitiatedTransactionEntityId] [bigint] NULL,
	[OwnerGroupId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
	[CloseFollowUp] [bit] NOT NULL,
	[ClosingComments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Activities]  WITH CHECK ADD  CONSTRAINT [EActivity_ActivityType] FOREIGN KEY([ActivityTypeId])
REFERENCES [dbo].[ActivityTypes] ([Id])
GO
ALTER TABLE [dbo].[Activities] CHECK CONSTRAINT [EActivity_ActivityType]
GO
ALTER TABLE [dbo].[Activities]  WITH CHECK ADD  CONSTRAINT [EActivity_DocumentList] FOREIGN KEY([DocumentListId])
REFERENCES [dbo].[DocumentLists] ([Id])
GO
ALTER TABLE [dbo].[Activities] CHECK CONSTRAINT [EActivity_DocumentList]
GO
ALTER TABLE [dbo].[Activities]  WITH CHECK ADD  CONSTRAINT [EActivity_Owner] FOREIGN KEY([OwnerId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Activities] CHECK CONSTRAINT [EActivity_Owner]
GO
ALTER TABLE [dbo].[Activities]  WITH CHECK ADD  CONSTRAINT [EActivity_OwnerGroup] FOREIGN KEY([OwnerGroupId])
REFERENCES [dbo].[UserGroups] ([Id])
GO
ALTER TABLE [dbo].[Activities] CHECK CONSTRAINT [EActivity_OwnerGroup]
GO
ALTER TABLE [dbo].[Activities]  WITH CHECK ADD  CONSTRAINT [EActivity_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[Activities] CHECK CONSTRAINT [EActivity_Portfolio]
GO
ALTER TABLE [dbo].[Activities]  WITH CHECK ADD  CONSTRAINT [EActivity_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[ActivityStatusConfigs] ([Id])
GO
ALTER TABLE [dbo].[Activities] CHECK CONSTRAINT [EActivity_Status]
GO
