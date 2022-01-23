CREATE TYPE [dbo].[TaxDepAmortizationGLHeader] AS TABLE(
	[EntityId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NULL,
	[ReversalPostDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[GLJournalId] [bigint] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
