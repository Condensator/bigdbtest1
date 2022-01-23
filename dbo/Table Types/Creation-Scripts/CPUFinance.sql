CREATE TYPE [dbo].[CPUFinance] AS TABLE(
	[CommencementDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayoffDate] [date] NULL,
	[DueDay] [int] NOT NULL,
	[ReadDay] [int] NULL,
	[BasePaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsAdvanceBilling] [bit] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
