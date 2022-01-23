SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OneTimeACHRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[BankAccountId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TotalAmount_Amount] [decimal](16, 2) NOT NULL,
	[TotalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalAmountToPay_Amount] [decimal](16, 2) NOT NULL,
	[TotalAmountToPay_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OneTimeACHRequests]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHRequest_BankAccount] FOREIGN KEY([BankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHRequests] CHECK CONSTRAINT [EOneTimeACHRequest_BankAccount]
GO
ALTER TABLE [dbo].[OneTimeACHRequests]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHRequest_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHRequests] CHECK CONSTRAINT [EOneTimeACHRequest_Currency]
GO
ALTER TABLE [dbo].[OneTimeACHRequests]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHRequest_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHRequests] CHECK CONSTRAINT [EOneTimeACHRequest_Customer]
GO
