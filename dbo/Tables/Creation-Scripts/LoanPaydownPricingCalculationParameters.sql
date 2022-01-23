SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPaydownPricingCalculationParameters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DiscountRate] [decimal](8, 4) NULL,
	[Factor] [decimal](8, 4) NULL,
	[NumberofTerms] [int] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LoanPaydownPricingDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PaydownTemplateCalculationParameterId] [bigint] NULL,
	[DailyFinanceAsOfDate] [date] NULL,
	[InterestPenaltyAmount_Amount] [decimal](16, 2) NOT NULL,
	[InterestPenaltyAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPaydownPricingCalculationParameters]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownPricingCalculationParameter_PaydownTemplateCalculationParameter] FOREIGN KEY([PaydownTemplateCalculationParameterId])
REFERENCES [dbo].[PaydownTemplateCalculationParameters] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownPricingCalculationParameters] CHECK CONSTRAINT [ELoanPaydownPricingCalculationParameter_PaydownTemplateCalculationParameter]
GO
ALTER TABLE [dbo].[LoanPaydownPricingCalculationParameters]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownPricingDetail_LoanPaydownPricingCalculationParameters] FOREIGN KEY([LoanPaydownPricingDetailId])
REFERENCES [dbo].[LoanPaydownPricingDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPaydownPricingCalculationParameters] CHECK CONSTRAINT [ELoanPaydownPricingDetail_LoanPaydownPricingCalculationParameters]
GO
