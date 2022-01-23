CREATE TYPE [dbo].[GLEntryItem] AS TABLE(
	[Name] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLSystemDefinedBook] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsDebit] [bit] NOT NULL,
	[TypicalAccount] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[SortOrder] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[GLTransactionTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
