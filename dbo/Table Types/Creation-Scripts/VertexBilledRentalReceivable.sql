CREATE TYPE [dbo].[VertexBilledRentalReceivable] AS TABLE(
	[RevenueBilledToDate_Amount] [decimal](16, 2) NOT NULL,
	[RevenueBilledToDate_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CumulativeAmount_Amount] [decimal](16, 2) NOT NULL,
	[CumulativeAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[ReceivableDetailId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[AssetSKUId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
