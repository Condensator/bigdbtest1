CREATE TYPE [dbo].[RecentTransactionParameters] AS TABLE(
	[EntityType] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[TransactionName] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[Transaction] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReferenceNumber] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[Description] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[UserId] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL
)
GO
