CREATE TYPE [dbo].[ReceivableForTransferPaymentDetail] AS TABLE(
	[DueDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[PaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsResidualPayment] [bit] NOT NULL,
	[PaymentScheduleId] [bigint] NULL,
	[ContractId] [bigint] NOT NULL,
	[ReceivableForTransferFundingSourceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
