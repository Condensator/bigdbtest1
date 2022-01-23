SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DecisionTableLogs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[RuleName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Conditions] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Result] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NOT NULL,
	[EntityTypeId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DecisionTableTypeConfigName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DecisionTableLogs]  WITH CHECK ADD  CONSTRAINT [EDecisionTableLog_EntityType] FOREIGN KEY([EntityTypeId])
REFERENCES [dbo].[EntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[DecisionTableLogs] CHECK CONSTRAINT [EDecisionTableLog_EntityType]
GO
