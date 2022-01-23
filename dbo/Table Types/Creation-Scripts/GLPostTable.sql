CREATE TYPE [dbo].[GLPostTable] AS TABLE(
	[TableName] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[PrimaryId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[IsGLPosted] [bit] NULL,
	[PostDate] [datetime] NULL
)
GO
