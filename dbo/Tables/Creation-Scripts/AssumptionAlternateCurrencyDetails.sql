SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssumptionAlternateCurrencyDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BillingExchangeRate] [decimal](20, 10) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BillingCurrencyId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssumptionAlternateCurrencyDetails]  WITH CHECK ADD  CONSTRAINT [EAssumption_AssumptionAlternateCurrencyDetails] FOREIGN KEY([AssumptionId])
REFERENCES [dbo].[Assumptions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssumptionAlternateCurrencyDetails] CHECK CONSTRAINT [EAssumption_AssumptionAlternateCurrencyDetails]
GO
ALTER TABLE [dbo].[AssumptionAlternateCurrencyDetails]  WITH CHECK ADD  CONSTRAINT [EAssumptionAlternateCurrencyDetail_BillingCurrency] FOREIGN KEY([BillingCurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[AssumptionAlternateCurrencyDetails] CHECK CONSTRAINT [EAssumptionAlternateCurrencyDetail_BillingCurrency]
GO
