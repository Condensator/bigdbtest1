CREATE TYPE [dbo].[LoanFinanceAdditionalCharge] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AdditionalChargeId] [bigint] NOT NULL,
	[SundryId] [bigint] NULL,
	[RecurringSundryId] [bigint] NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
