CREATE TYPE [dbo].[PayableInvoiceOtherCostSKUDetail] AS TABLE(
	[OtherCost_Amount] [decimal](16, 2) NOT NULL,
	[OtherCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TotalCost_Amount] [decimal](16, 2) NOT NULL,
	[TotalCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PayableInvoiceAssetSKUId] [bigint] NOT NULL,
	[PayableInvoiceOtherCostId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
