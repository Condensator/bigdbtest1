CREATE TYPE [dbo].[AssetsLocationChangeDetail] AS TABLE(
	[ReciprocityAmount_Amount] [decimal](16, 2) NULL,
	[ReciprocityAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LienCredit_Amount] [decimal](16, 2) NULL,
	[LienCredit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsFLStampTaxExempt] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetsLocationChangeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
