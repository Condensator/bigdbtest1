CREATE TYPE [dbo].[BankAccountInfoType] AS TABLE(
	[BankId] [bigint] NULL,
	[FourDigitAccountNumber] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL
)
GO
