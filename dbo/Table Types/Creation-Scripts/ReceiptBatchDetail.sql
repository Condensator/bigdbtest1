CREATE TYPE [dbo].[ReceiptBatchDetail] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptId] [bigint] NOT NULL,
	[ReceiptBatchId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
