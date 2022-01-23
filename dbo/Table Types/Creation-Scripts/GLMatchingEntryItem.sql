CREATE TYPE [dbo].[GLMatchingEntryItem] AS TABLE(
	[Filter] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[MatchingEntryItemId] [bigint] NOT NULL,
	[GLEntryItemId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
