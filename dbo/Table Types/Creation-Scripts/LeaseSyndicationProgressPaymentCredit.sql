CREATE TYPE [dbo].[LeaseSyndicationProgressPaymentCredit] AS TABLE(
	[TakeDownAmount_Amount] [decimal](16, 2) NOT NULL,
	[TakeDownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[OtherCostCapitalizedAmount_Amount] [decimal](16, 2) NULL,
	[OtherCostCapitalizedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PayableInvoiceOtherCostId] [bigint] NOT NULL,
	[LeaseSyndicationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
