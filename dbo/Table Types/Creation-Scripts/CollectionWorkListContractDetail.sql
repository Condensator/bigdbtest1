CREATE TYPE [dbo].[CollectionWorkListContractDetail] AS TABLE(
	[IsWorkCompleted] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CompletionReason] [nvarchar](29) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NOT NULL,
	[CollectionWorkListId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
