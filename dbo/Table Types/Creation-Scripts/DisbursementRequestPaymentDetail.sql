CREATE TYPE [dbo].[DisbursementRequestPaymentDetail] AS TABLE(
	[RequestedPaymentDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Urgency] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Memo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[RemittanceType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[TotalAmountToPay_Amount] [decimal](16, 2) NULL,
	[TotalAmountToPay_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[MailingInstruction] [nvarchar](2) COLLATE Latin1_General_CI_AS NULL,
	[PayeeId] [bigint] NOT NULL,
	[RemitToId] [bigint] NULL,
	[ContactId] [bigint] NULL,
	[PayFromAccountId] [bigint] NULL,
	[DisbursementRequestId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
