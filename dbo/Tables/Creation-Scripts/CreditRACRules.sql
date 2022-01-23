SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditRACRules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Type] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[RuleDisplayText] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActualValue] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Result] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RACRuleId] [bigint] NOT NULL,
	[CreditRACId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BusinessDeclineReasonCode] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditRACRules]  WITH CHECK ADD  CONSTRAINT [ECreditRAC_CreditRACRules] FOREIGN KEY([CreditRACId])
REFERENCES [dbo].[CreditRACs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditRACRules] CHECK CONSTRAINT [ECreditRAC_CreditRACRules]
GO
ALTER TABLE [dbo].[CreditRACRules]  WITH CHECK ADD  CONSTRAINT [ECreditRACRule_RACRule] FOREIGN KEY([RACRuleId])
REFERENCES [dbo].[RACRules] ([Id])
GO
ALTER TABLE [dbo].[CreditRACRules] CHECK CONSTRAINT [ECreditRACRule_RACRule]
GO
