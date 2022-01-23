CREATE TYPE [dbo].[LoanFinanceWHTDetail] AS TABLE(
	[IsApplicableForWHT] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveFromDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
