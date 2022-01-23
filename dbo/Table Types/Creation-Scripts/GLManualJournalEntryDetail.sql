CREATE TYPE [dbo].[GLManualJournalEntryDetail] AS TABLE(
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsDebit] [bit] NOT NULL,
	[GLAccountNumber] [nvarchar](129) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[GLAccountId] [bigint] NOT NULL,
	[GLJournalDetailId] [bigint] NULL,
	[ReversalGLJournalDetailId] [bigint] NULL,
	[GLManualJournalEntryId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
