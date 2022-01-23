CREATE TYPE [dbo].[AccountsPayablePaymentVoucher] AS TABLE(
	[RequestedDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OverNightRequired] [bit] NOT NULL,
	[IsManual] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PaymentVoucherId] [bigint] NOT NULL,
	[AccountsPayablePaymentId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
