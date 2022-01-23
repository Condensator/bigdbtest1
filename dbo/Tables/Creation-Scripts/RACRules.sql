SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RACRules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RuleDisplayText] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[MinDate] [date] NULL,
	[MaxDate] [date] NULL,
	[MinNumber] [int] NULL,
	[MaxNumber] [int] NULL,
	[Percentage] [decimal](5, 2) NULL,
	[Bool] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[String] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RACRuleConfigId] [bigint] NOT NULL,
	[RACId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Min] [decimal](16, 2) NULL,
	[Max] [decimal](16, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RACRules]  WITH CHECK ADD  CONSTRAINT [ERAC_RACRules] FOREIGN KEY([RACId])
REFERENCES [dbo].[RACs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RACRules] CHECK CONSTRAINT [ERAC_RACRules]
GO
ALTER TABLE [dbo].[RACRules]  WITH CHECK ADD  CONSTRAINT [ERACRule_RACRuleConfig] FOREIGN KEY([RACRuleConfigId])
REFERENCES [dbo].[RACRuleConfigs] ([Id])
GO
ALTER TABLE [dbo].[RACRules] CHECK CONSTRAINT [ERACRule_RACRuleConfig]
GO
