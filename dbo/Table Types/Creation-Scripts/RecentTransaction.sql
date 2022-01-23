CREATE TYPE [dbo].[RecentTransaction] AS TABLE(
	[EntityType] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityId] [bigint] NOT NULL,
	[TransactionName] [nvarchar](22) COLLATE Latin1_General_CI_AS NOT NULL,
	[Transaction] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReferenceNumber] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CustomerId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
