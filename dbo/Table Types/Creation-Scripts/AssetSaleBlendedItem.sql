CREATE TYPE [dbo].[AssetSaleBlendedItem] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL,
	[SundryId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[AssetSaleId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
