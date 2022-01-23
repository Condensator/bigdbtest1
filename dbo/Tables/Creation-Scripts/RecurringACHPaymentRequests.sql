SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RecurringACHPaymentRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EmailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[PaymentType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[RecurringPaymentMethod] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[DayoftheMonth] [int] NULL,
	[StartDate] [date] NOT NULL,
	[IsEndPaymentOnMaturity] [bit] NOT NULL,
	[EndDate] [date] NULL,
	[PaymentThreshold] [bit] NOT NULL,
	[PaymentThresholdAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaymentThresholdAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AllReceivableTypes] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ContractId] [bigint] NULL,
	[BankAccountId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RecurringACHPaymentRequests]  WITH CHECK ADD  CONSTRAINT [ERecurringACHPaymentRequest_BankAccount] FOREIGN KEY([BankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[RecurringACHPaymentRequests] CHECK CONSTRAINT [ERecurringACHPaymentRequest_BankAccount]
GO
ALTER TABLE [dbo].[RecurringACHPaymentRequests]  WITH CHECK ADD  CONSTRAINT [ERecurringACHPaymentRequest_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[RecurringACHPaymentRequests] CHECK CONSTRAINT [ERecurringACHPaymentRequest_Contract]
GO
ALTER TABLE [dbo].[RecurringACHPaymentRequests]  WITH CHECK ADD  CONSTRAINT [ERecurringACHPaymentRequest_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[RecurringACHPaymentRequests] CHECK CONSTRAINT [ERecurringACHPaymentRequest_Customer]
GO
