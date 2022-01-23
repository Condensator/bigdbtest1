CREATE TYPE [dbo].[TreasuryPayableInfo] AS TABLE(
	[Key] [bigint] NOT NULL,
	[PayableId] [bigint] NOT NULL,
	[TreasuryPayableStatus] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApprovalComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Urgency] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Memo] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[PayFromAccountId] [bigint] NULL,
	[MailingInstruction] [nvarchar](2) COLLATE Latin1_General_CI_AS NULL,
	[ContractSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PayableInvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TransactionNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableOffsetAmount] [decimal](16, 2) NOT NULL,
	[ShouldCreateTP] [bit] NOT NULL
)
GO
