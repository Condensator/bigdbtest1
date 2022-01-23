CREATE TYPE [dbo].[TaxDepSetupJournalDetailParam] AS TABLE(
	[RecordCount] [bigint] NULL,
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
	[LineofBusinessId] [bigint] NULL,
	[IsActive] [bit] NULL,
	[InstrumentTypeGLAccountId] [bigint] NULL
)
GO
