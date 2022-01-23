CREATE TYPE [dbo].[CustomerACHAssignment] AS TABLE(
	[AssignmentNumber] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaymentType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[RecurringPaymentMethod] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[DayoftheMonth] [int] NOT NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[BankAccountId] [bigint] NULL,
	[RecurringACHPaymentRequestId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
