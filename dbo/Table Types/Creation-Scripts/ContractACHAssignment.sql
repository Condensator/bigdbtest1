CREATE TYPE [dbo].[ContractACHAssignment] AS TABLE(
	[AssignmentNumber] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BeginDate] [date] NULL,
	[EndDate] [date] NULL,
	[PaymentType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[RecurringPaymentMethod] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[DayoftheMonth] [int] NOT NULL,
	[IsEndPaymentOnMaturity] [bit] NOT NULL,
	[ReceivableTypeId] [bigint] NULL,
	[BankAccountId] [bigint] NULL,
	[RecurringACHPaymentRequestId] [bigint] NULL,
	[ContractBillingId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
