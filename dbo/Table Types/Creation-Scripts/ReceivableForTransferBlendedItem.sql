CREATE TYPE [dbo].[ReceivableForTransferBlendedItem] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FundingSourceId] [bigint] NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[ReceivableForTransferId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
