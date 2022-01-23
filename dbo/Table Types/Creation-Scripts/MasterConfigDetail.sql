CREATE TYPE [dbo].[MasterConfigDetail] AS TABLE(
	[ConfigType] [nvarchar](31) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[ProcessingOrder] [decimal](16, 2) NOT NULL,
	[IsRoot] [bit] NOT NULL,
	[DynamicFilterConditions] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[NonEditableColumns] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CanAddRows] [bit] NOT NULL,
	[RowSecurityConditions] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreateTransactionName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EditTransactionName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[TransactionScriptName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SelectorName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[MasterConfigEntityId] [bigint] NOT NULL,
	[MasterConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
