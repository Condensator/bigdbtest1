CREATE TYPE [dbo].[PayoffReceivableDetail] AS TABLE(
	[ReceivableDetailKey] [bigint] NULL,
	[ReceivableKey] [bigint] NULL,
	[Amount] [decimal](18, 2) NULL,
	[ContractId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DueDate] [date] NULL,
	[LocationId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[IsLeaseBased] [bit] NULL,
	[ReceivableCodeId] [bigint] NULL
)
GO
