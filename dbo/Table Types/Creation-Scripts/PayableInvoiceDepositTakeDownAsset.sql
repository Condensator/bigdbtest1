CREATE TYPE [dbo].[PayableInvoiceDepositTakeDownAsset] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TakeDownAmount_Amount] [decimal](16, 2) NOT NULL,
	[TakeDownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TakeDownAssetId] [bigint] NOT NULL,
	[NegativeDepositAssetId] [bigint] NULL,
	[PayableInvoiceDepositAssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
