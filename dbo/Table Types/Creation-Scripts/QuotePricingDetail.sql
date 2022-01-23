CREATE TYPE [dbo].[QuotePricingDetail] AS TABLE(
	[PurchasePrice_Amount] [decimal](16, 2) NULL,
	[PurchasePrice_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DownPaymentAmount_Amount] [decimal](16, 2) NULL,
	[DownPaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AdvanceToDealer_Amount] [decimal](16, 2) NULL,
	[AdvanceToDealer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestRate] [decimal](5, 2) NULL,
	[APR] [decimal](5, 2) NULL,
	[QuoteLeaseTypeId] [bigint] NOT NULL,
	[DownPaymentPercentageId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
