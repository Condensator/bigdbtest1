SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EscrowAccounts](
	[Id] [bigint] NOT NULL,
	[EscrowAccountNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EscrowAccountOpenDate] [date] NULL,
	[EscrowAgentContactName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EscrowAgentContactPhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[EscrowAgentEmail] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[EscrowAgentNameCompany] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SalesRepName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AccountStatus] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
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
ALTER TABLE [dbo].[EscrowAccounts]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucher_EscrowAccount] FOREIGN KEY([Id])
REFERENCES [dbo].[PaymentVouchers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EscrowAccounts] CHECK CONSTRAINT [EPaymentVoucher_EscrowAccount]
GO
