SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DecisionTypeQualifierConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QualifyingTypeId] [bigint] NULL,
	[DecisionTableTypeConfigId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[DecisionTypeQualifierConfigs]  WITH CHECK ADD  CONSTRAINT [EDecisionTableTypeConfig_DecisionTypeQualifierConfigs] FOREIGN KEY([DecisionTableTypeConfigId])
REFERENCES [dbo].[DecisionTableTypeConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DecisionTypeQualifierConfigs] CHECK CONSTRAINT [EDecisionTableTypeConfig_DecisionTypeQualifierConfigs]
GO
ALTER TABLE [dbo].[DecisionTypeQualifierConfigs]  WITH CHECK ADD  CONSTRAINT [EDecisionTypeQualifierConfig_QualifyingType] FOREIGN KEY([QualifyingTypeId])
REFERENCES [dbo].[DecisionTableTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[DecisionTypeQualifierConfigs] CHECK CONSTRAINT [EDecisionTypeQualifierConfig_QualifyingType]
GO
