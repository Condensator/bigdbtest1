CREATE TYPE [dbo].[ContractFloatRate] AS TABLE(
	[EffectiveDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsProcessed] [bit] NOT NULL,
	[IsAutoRestructureProcessed] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsProcessedByPaymentSchedule] [bit] NOT NULL,
	[FloatRateId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
