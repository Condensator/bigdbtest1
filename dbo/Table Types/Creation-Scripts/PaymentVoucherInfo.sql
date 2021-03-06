CREATE TYPE [dbo].[PaymentVoucherInfo] AS TABLE(
	[RemittanceType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RequestedDate] [date] NOT NULL,
	[PaymentVoucherStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Memo] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Urgency] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[PayeeName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[IsManual] [bit] NOT NULL,
	[MailingInstruction] [nvarchar](2) COLLATE Latin1_General_CI_AS NULL,
	[ClearingOption] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableDueDate] [date] NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
	[WithholdingTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[WithholdingTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[PayFromAccountId] [bigint] NOT NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[ReceivableRemitToId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[SundryId] [bigint] NULL,
	[APGLTemplateId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[AccountsPayableId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
