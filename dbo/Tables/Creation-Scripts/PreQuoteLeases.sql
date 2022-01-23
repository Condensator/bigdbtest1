SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuoteLeases](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PreQuoteContractId] [bigint] NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PayoffId] [bigint] NULL,
	[ManagementYield] [decimal](28, 18) NOT NULL,
	[Payment_Amount] [decimal](16, 2) NOT NULL,
	[Payment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RemainingRentalReceivable_Amount] [decimal](16, 2) NOT NULL,
	[RemainingRentalReceivable_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RemainingIncomeBalance_Amount] [decimal](16, 2) NOT NULL,
	[RemainingIncomeBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BookedResidual_Amount] [decimal](16, 2) NOT NULL,
	[BookedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPIncome_Amount] [decimal](16, 2) NOT NULL,
	[OTPIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPDepreciation_Amount] [decimal](16, 2) NOT NULL,
	[OTPDepreciation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPStartDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuoteLeases]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuoteLeases] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuoteLeases] CHECK CONSTRAINT [EPreQuote_PreQuoteLeases]
GO
ALTER TABLE [dbo].[PreQuoteLeases]  WITH CHECK ADD  CONSTRAINT [EPreQuoteLease_LeaseFinance] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteLeases] CHECK CONSTRAINT [EPreQuoteLease_LeaseFinance]
GO
ALTER TABLE [dbo].[PreQuoteLeases]  WITH CHECK ADD  CONSTRAINT [EPreQuoteLease_Payoff] FOREIGN KEY([PayoffId])
REFERENCES [dbo].[Payoffs] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteLeases] CHECK CONSTRAINT [EPreQuoteLease_Payoff]
GO
ALTER TABLE [dbo].[PreQuoteLeases]  WITH CHECK ADD  CONSTRAINT [EPreQuoteLease_PreQuoteContract] FOREIGN KEY([PreQuoteContractId])
REFERENCES [dbo].[PreQuoteContracts] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteLeases] CHECK CONSTRAINT [EPreQuoteLease_PreQuoteContract]
GO
