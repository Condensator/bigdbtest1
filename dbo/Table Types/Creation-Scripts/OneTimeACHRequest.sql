CREATE TYPE [dbo].[OneTimeACHRequest] AS TABLE(
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TotalAmount_Amount] [decimal](16, 2) NOT NULL,
	[TotalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalAmountToPay_Amount] [decimal](16, 2) NOT NULL,
	[TotalAmountToPay_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[BankAccountId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
