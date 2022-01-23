SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CollectionQueues](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RuleExpression] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PrimaryCollectionGroupId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[AssignmentMethod] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerAssignmentRuleExpression] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[AcrossQueue] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CollectionQueues]  WITH CHECK ADD  CONSTRAINT [ECollectionQueue_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[CollectionQueues] CHECK CONSTRAINT [ECollectionQueue_Portfolio]
GO
ALTER TABLE [dbo].[CollectionQueues]  WITH CHECK ADD  CONSTRAINT [ECollectionQueue_PrimaryCollectionGroup] FOREIGN KEY([PrimaryCollectionGroupId])
REFERENCES [dbo].[UserGroups] ([Id])
GO
ALTER TABLE [dbo].[CollectionQueues] CHECK CONSTRAINT [ECollectionQueue_PrimaryCollectionGroup]
GO
