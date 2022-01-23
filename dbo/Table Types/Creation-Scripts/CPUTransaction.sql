CREATE TYPE [dbo].[CPUTransaction] AS TABLE(
	[ReferenceNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Date] [date] NOT NULL,
	[TransactionType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[InActiveReason] [nvarchar](22) COLLATE Latin1_General_CI_AS NULL,
	[CPUContractId] [bigint] NOT NULL,
	[CPUFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
