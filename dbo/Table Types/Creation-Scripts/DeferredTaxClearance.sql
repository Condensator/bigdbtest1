CREATE TYPE [dbo].[DeferredTaxClearance] AS TABLE(
	[ClearedAmount_Amount] [decimal](16, 2) NOT NULL,
	[ClearedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ClearedDate] [date] NOT NULL,
	[SourceId] [bigint] NOT NULL,
	[SourceTable] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[GLTemplateId] [bigint] NULL,
	[JournalId] [bigint] NULL,
	[DeferredTaxId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
