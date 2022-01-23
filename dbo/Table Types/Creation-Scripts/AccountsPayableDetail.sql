CREATE TYPE [dbo].[AccountsPayableDetail] AS TABLE(
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RequestedPaymentDate] [date] NOT NULL,
	[ReceiptType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Urgency] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Memo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[ApprovalComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[MailingInstruction] [nvarchar](2) COLLATE Latin1_General_CI_AS NULL,
	[WithholdingTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[WithholdingTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TreasuryPayableId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[PayFromAccountId] [bigint] NOT NULL,
	[AccountsPayableId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
