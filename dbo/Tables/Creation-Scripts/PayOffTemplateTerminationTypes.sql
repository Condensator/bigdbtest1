SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayOffTemplateTerminationTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ConditionalCalculation] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayoffTemplateTerminationTypeConfigId] [bigint] NOT NULL,
	[PayoffTerminationExpressionId] [bigint] NULL,
	[PayOffTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypes]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplate_PayOffTemplateTerminationTypes] FOREIGN KEY([PayOffTemplateId])
REFERENCES [dbo].[PayOffTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypes] CHECK CONSTRAINT [EPayOffTemplate_PayOffTemplateTerminationTypes]
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypes]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplateTerminationType_PayoffTemplateTerminationTypeConfig] FOREIGN KEY([PayoffTemplateTerminationTypeConfigId])
REFERENCES [dbo].[PayoffTemplateTerminationTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypes] CHECK CONSTRAINT [EPayOffTemplateTerminationType_PayoffTemplateTerminationTypeConfig]
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypes]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplateTerminationType_PayoffTerminationExpression] FOREIGN KEY([PayoffTerminationExpressionId])
REFERENCES [dbo].[PayoffTerminationExpressions] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypes] CHECK CONSTRAINT [EPayOffTemplateTerminationType_PayoffTerminationExpression]
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypes]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplateTerminationType_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplateTerminationTypes] CHECK CONSTRAINT [EPayOffTemplateTerminationType_Portfolio]
GO
