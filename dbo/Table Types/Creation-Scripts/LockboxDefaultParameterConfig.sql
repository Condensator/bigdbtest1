CREATE TYPE [dbo].[LockboxDefaultParameterConfig] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[CurrencyId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CashTypeId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
