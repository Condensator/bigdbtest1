SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DecisionTables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[EntityId] [bigint] NOT NULL,
	[TypeId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DecisionTables]  WITH CHECK ADD  CONSTRAINT [EDecisionTable_Entity] FOREIGN KEY([EntityId])
REFERENCES [dbo].[EntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[DecisionTables] CHECK CONSTRAINT [EDecisionTable_Entity]
GO
ALTER TABLE [dbo].[DecisionTables]  WITH CHECK ADD  CONSTRAINT [EDecisionTable_Type] FOREIGN KEY([TypeId])
REFERENCES [dbo].[DecisionTableTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[DecisionTables] CHECK CONSTRAINT [EDecisionTable_Type]
GO