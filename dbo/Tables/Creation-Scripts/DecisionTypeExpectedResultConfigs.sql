SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DecisionTypeExpectedResultConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ExpectedResultType] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
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
ALTER TABLE [dbo].[DecisionTypeExpectedResultConfigs]  WITH CHECK ADD  CONSTRAINT [EDecisionTableTypeConfig_DecisionTypeExpectedResultConfigs] FOREIGN KEY([DecisionTableTypeConfigId])
REFERENCES [dbo].[DecisionTableTypeConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DecisionTypeExpectedResultConfigs] CHECK CONSTRAINT [EDecisionTableTypeConfig_DecisionTypeExpectedResultConfigs]
GO
