SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseFinanceAlternateCurrencyDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BillingExchangeRate] [decimal](20, 10) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BillingCurrencyId] [bigint] NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseFinanceAlternateCurrencyDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LeaseFinanceAlternateCurrencyDetails] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseFinanceAlternateCurrencyDetails] CHECK CONSTRAINT [ELeaseFinance_LeaseFinanceAlternateCurrencyDetails]
GO
ALTER TABLE [dbo].[LeaseFinanceAlternateCurrencyDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceAlternateCurrencyDetail_BillingCurrency] FOREIGN KEY([BillingCurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceAlternateCurrencyDetails] CHECK CONSTRAINT [ELeaseFinanceAlternateCurrencyDetail_BillingCurrency]
GO
