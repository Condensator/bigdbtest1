SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingPaydowns](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Alias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AccountingDate] [date] NULL,
	[AccruedInterest_Amount] [decimal](16, 2) NULL,
	[AccruedInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[DueDate] [date] NULL,
	[GainLoss_Amount] [decimal](16, 2) NOT NULL,
	[GainLoss_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GoodThroughDate] [date] NULL,
	[InterestOutstanding_Amount] [decimal](16, 2) NULL,
	[InterestOutstanding_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestPaydown_Amount] [decimal](16, 2) NULL,
	[InterestPaydown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsPaydownFromDiscounting] [bit] NOT NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[PaydownAmortOption] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[PaydownAtInception] [bit] NOT NULL,
	[PaydownDate] [date] NULL,
	[PostDate] [date] NULL,
	[PrincipalBalance_Amount] [decimal](16, 2) NULL,
	[PrincipalBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PrincipalOutstanding_Amount] [decimal](16, 2) NULL,
	[PrincipalOutstanding_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PrincipalPaydown_Amount] [decimal](16, 2) NULL,
	[PrincipalPaydown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[QuoteNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaydownType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[DiscountingFinanceId] [bigint] NOT NULL,
	[DiscountingRepaymentId] [bigint] NULL,
	[PaydownGLTemplateId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[DiscountingAmendmentId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsRepaymentScheduleGenerated] [bit] NOT NULL,
	[IsRepaymentScheduleParametersChanged] [bit] NOT NULL,
	[Yield] [decimal](14, 9) NULL,
	[NumberOfPayments] [int] NULL,
	[Calculate] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[TotalPayments] [int] NULL,
	[Term] [decimal](10, 6) NULL,
	[MaturityDate] [date] NULL,
	[RegularPaymentAmount_Amount] [decimal](16, 2) NULL,
	[RegularPaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsRepaymentPricingPerformed] [bit] NOT NULL,
	[IsRepaymentPricingParametersChanged] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingPaydowns]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydown_DiscountingAmendment] FOREIGN KEY([DiscountingAmendmentId])
REFERENCES [dbo].[DiscountingAmendments] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydowns] CHECK CONSTRAINT [EDiscountingPaydown_DiscountingAmendment]
GO
ALTER TABLE [dbo].[DiscountingPaydowns]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydown_DiscountingFinance] FOREIGN KEY([DiscountingFinanceId])
REFERENCES [dbo].[DiscountingFinances] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydowns] CHECK CONSTRAINT [EDiscountingPaydown_DiscountingFinance]
GO
ALTER TABLE [dbo].[DiscountingPaydowns]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydown_DiscountingRepayment] FOREIGN KEY([DiscountingRepaymentId])
REFERENCES [dbo].[DiscountingRepaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydowns] CHECK CONSTRAINT [EDiscountingPaydown_DiscountingRepayment]
GO
ALTER TABLE [dbo].[DiscountingPaydowns]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydown_PaydownGLTemplate] FOREIGN KEY([PaydownGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydowns] CHECK CONSTRAINT [EDiscountingPaydown_PaydownGLTemplate]
GO
ALTER TABLE [dbo].[DiscountingPaydowns]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydown_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydowns] CHECK CONSTRAINT [EDiscountingPaydown_RemitTo]
GO
