CREATE TYPE [dbo].[ContractAssumptionHistory] AS TABLE(
	[AssumptionDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[FinanceId] [bigint] NOT NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[BillToId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
