CREATE TYPE [dbo].[ReceivableInvoiceDeliquencyDetail] AS TABLE(
	[IsOneToThirtyDaysLate] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsThirtyPlusDaysLate] [bit] NOT NULL,
	[IsSixtyPlusDaysLate] [bit] NOT NULL,
	[IsNinetyPlusDaysLate] [bit] NOT NULL,
	[IsOneHundredTwentyPlusDaysLate] [bit] NOT NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
