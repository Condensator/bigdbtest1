SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CostConfigurations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BreakdownAmount_Amount] [decimal](16, 2) NOT NULL,
	[BreakdownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CostTypeId] [bigint] NOT NULL,
	[CreditDecisionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AdjustmentFactor] [decimal](18, 8) NOT NULL,
	[AdjustmentAmount_Amount] [decimal](16, 2) NOT NULL,
	[AdjustmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CostConfigurations]  WITH CHECK ADD  CONSTRAINT [ECostConfiguration_CostType] FOREIGN KEY([CostTypeId])
REFERENCES [dbo].[CostTypes] ([Id])
GO
ALTER TABLE [dbo].[CostConfigurations] CHECK CONSTRAINT [ECostConfiguration_CostType]
GO
ALTER TABLE [dbo].[CostConfigurations]  WITH CHECK ADD  CONSTRAINT [ECreditDecision_CostConfigurations] FOREIGN KEY([CreditDecisionId])
REFERENCES [dbo].[CreditDecisions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CostConfigurations] CHECK CONSTRAINT [ECreditDecision_CostConfigurations]
GO
