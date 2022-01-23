CREATE TYPE [dbo].[AssetValueHistoryDetail] AS TABLE(
	[AmountPosted_Amount] [decimal](16, 2) NOT NULL,
	[AmountPosted_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[ReceiptApplicationReceivableDetailId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[AssetValueHistoryId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
