CREATE TYPE [dbo].[ReceiptJournalDetailParam] AS TABLE(
	[EntityId] [bigint] NULL,
	[EntityType] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Amount] [decimal](16, 2) NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsDebit] [bit] NULL,
	[GLAccountNumber] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NULL,
	[GLAccountId] [bigint] NULL,
	[GLTemplateDetailId] [bigint] NULL,
	[MatchingGLTemplateDetailId] [bigint] NULL,
	[IsActive] [bit] NULL,
	[SourceType] [varchar](15) COLLATE Latin1_General_CI_AS NULL,
	[LineofBusinessId] [bigint] NULL,
	[UniqueIdentifier] [bigint] NULL
)
GO
