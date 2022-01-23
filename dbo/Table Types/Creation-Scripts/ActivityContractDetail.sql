CREATE TYPE [dbo].[ActivityContractDetail] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaymentNumber] [int] NULL,
	[InitiatedTransactionEntityId] [bigint] NULL,
	[FullPayoff] [bit] NOT NULL,
	[TerminationReason] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NOT NULL,
	[ActivityForCustomerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
