SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditRACs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Result] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[Use] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RACId] [bigint] NOT NULL,
	[CreditDecisionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[BusinessDeclineReasonCode] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditRACs]  WITH CHECK ADD  CONSTRAINT [ECreditDecision_CreditRACs] FOREIGN KEY([CreditDecisionId])
REFERENCES [dbo].[CreditDecisions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditRACs] CHECK CONSTRAINT [ECreditDecision_CreditRACs]
GO
ALTER TABLE [dbo].[CreditRACs]  WITH CHECK ADD  CONSTRAINT [ECreditRAC_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[CreditRACs] CHECK CONSTRAINT [ECreditRAC_Portfolio]
GO
ALTER TABLE [dbo].[CreditRACs]  WITH CHECK ADD  CONSTRAINT [ECreditRAC_RAC] FOREIGN KEY([RACId])
REFERENCES [dbo].[RACs] ([Id])
GO
ALTER TABLE [dbo].[CreditRACs] CHECK CONSTRAINT [ECreditRAC_RAC]
GO
