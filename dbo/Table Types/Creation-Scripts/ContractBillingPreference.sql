CREATE TYPE [dbo].[ContractBillingPreference] AS TABLE(
	[InvoicePreference] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveFromDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[ContractBillingId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
