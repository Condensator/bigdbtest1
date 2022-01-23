CREATE TYPE [dbo].[ReceiptChunkerForPostingDetail_Extract] AS TABLE(
	[ReceiptId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptChunkerForPosting_ExtractId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
