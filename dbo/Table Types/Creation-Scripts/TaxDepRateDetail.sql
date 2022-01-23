CREATE TYPE [dbo].[TaxDepRateDetail] AS TABLE(
	[YearNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PeriodNumber] [int] NOT NULL,
	[DepreciationPercent] [decimal](6, 3) NOT NULL,
	[TaxDepRateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
