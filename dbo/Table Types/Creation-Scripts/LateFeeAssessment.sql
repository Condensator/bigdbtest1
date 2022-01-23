CREATE TYPE [dbo].[LateFeeAssessment] AS TABLE(
	[LateFeeAssessedUntilDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FullyAssessed] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ContractId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
