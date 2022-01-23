SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityGroups](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AutoImportForEntity] [bit] NOT NULL,
	[RuleExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityGroups]  WITH CHECK ADD  CONSTRAINT [EActivityGroup_EntityType] FOREIGN KEY([EntityTypeId])
REFERENCES [dbo].[ActivityEntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[ActivityGroups] CHECK CONSTRAINT [EActivityGroup_EntityType]
GO
ALTER TABLE [dbo].[ActivityGroups]  WITH CHECK ADD  CONSTRAINT [EActivityGroup_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[ActivityGroups] CHECK CONSTRAINT [EActivityGroup_Portfolio]
GO
