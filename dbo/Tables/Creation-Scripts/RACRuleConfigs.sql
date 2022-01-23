SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RACRuleConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[DisplayText] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[DataType] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](25) COLLATE Latin1_General_CI_AS NOT NULL,
	[RuleExpression] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[ParameterLabel] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsSystemControlled] [bit] NOT NULL,
	[NullDefaultValue] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[BusinessDeclineReasonCodeConfigId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RACRuleConfigs]  WITH CHECK ADD  CONSTRAINT [ERACRuleConfig_BusinessDeclineReasonCodeConfig] FOREIGN KEY([BusinessDeclineReasonCodeConfigId])
REFERENCES [dbo].[BusinessDeclineReasonCodeConfigs] ([Id])
GO
ALTER TABLE [dbo].[RACRuleConfigs] CHECK CONSTRAINT [ERACRuleConfig_BusinessDeclineReasonCodeConfig]
GO
ALTER TABLE [dbo].[RACRuleConfigs]  WITH CHECK ADD  CONSTRAINT [ERACRuleConfig_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[RACRuleConfigs] CHECK CONSTRAINT [ERACRuleConfig_Portfolio]
GO
