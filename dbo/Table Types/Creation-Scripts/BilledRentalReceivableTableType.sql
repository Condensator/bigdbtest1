CREATE TYPE [dbo].[BilledRentalReceivableTableType] AS TABLE(
	[RevenueBilledToDate_Amount] [decimal](30, 2) NULL,
	[RevenueBilledToDate_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CumulativeAmount_Amount] [decimal](30, 2) NULL,
	[CumulativeAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[CreatedById] [bigint] NULL,
	[CreatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NULL
)
GO
