SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayoffPricingCalculationParameters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DiscountRate] [decimal](8, 4) NULL,
	[Factor] [decimal](8, 4) NULL,
	[NumberOfTerms] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayOffTemplateTerminationTypeParameterId] [bigint] NOT NULL,
	[PayoffPricingOptionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[InterestPenaltyAmount_Amount] [decimal](16, 2) NOT NULL,
	[InterestPenaltyAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DailyFinanceAsOfDate] [date] NULL,
	[CalculatedFMV_Amount] [decimal](16, 2) NOT NULL,
	[CalculatedFMV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayoffPricingCalculationParameters]  WITH CHECK ADD  CONSTRAINT [EPayoffPricingCalculationParameter_PayOffTemplateTerminationTypeParameter] FOREIGN KEY([PayOffTemplateTerminationTypeParameterId])
REFERENCES [dbo].[PayOffTemplateTerminationTypeParameters] ([Id])
GO
ALTER TABLE [dbo].[PayoffPricingCalculationParameters] CHECK CONSTRAINT [EPayoffPricingCalculationParameter_PayOffTemplateTerminationTypeParameter]
GO
ALTER TABLE [dbo].[PayoffPricingCalculationParameters]  WITH CHECK ADD  CONSTRAINT [EPayoffPricingOption_PayoffPricingCalculationParameters] FOREIGN KEY([PayoffPricingOptionId])
REFERENCES [dbo].[PayoffPricingOptions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayoffPricingCalculationParameters] CHECK CONSTRAINT [EPayoffPricingOption_PayoffPricingCalculationParameters]
GO
