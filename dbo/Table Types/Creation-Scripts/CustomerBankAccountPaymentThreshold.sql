CREATE TYPE [dbo].[CustomerBankAccountPaymentThreshold] AS TABLE(
	[PaymentThreshold] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaymentThresholdAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaymentThresholdAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EmailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[BankAccountId] [bigint] NOT NULL,
	[ThresholdExceededEmailTemplateId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
