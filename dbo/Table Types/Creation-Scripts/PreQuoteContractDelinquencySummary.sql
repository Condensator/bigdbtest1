CREATE TYPE [dbo].[PreQuoteContractDelinquencySummary] AS TABLE(
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Fifteendayslate] [bigint] NULL,
	[Thirtydayslate] [bigint] NULL,
	[Sixtydayslate] [bigint] NULL,
	[Nintydayslate] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
