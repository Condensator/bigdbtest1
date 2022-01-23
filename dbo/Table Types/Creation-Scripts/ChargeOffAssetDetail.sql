CREATE TYPE [dbo].[ChargeOffAssetDetail] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NetWritedown_Amount] [decimal](16, 2) NOT NULL,
	[NetWritedown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetInvestmentWithBlended_Amount] [decimal](16, 2) NOT NULL,
	[NetInvestmentWithBlended_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[ChargeOffId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
