CREATE TYPE [dbo].[WorkFlowHistoryRelatedEntityTransactionConfig] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TransactionConfigId] [bigint] NOT NULL,
	[WorkFlowHistoryRelatedEntityConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
