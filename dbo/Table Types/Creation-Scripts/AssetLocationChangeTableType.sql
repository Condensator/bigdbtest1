CREATE TYPE [dbo].[AssetLocationChangeTableType] AS TABLE(
	[AssetId] [bigint] NULL,
	[IsFLStampTaxExempt] [bit] NULL,
	[ReciprocityAmount_Amount] [decimal](16, 2) NULL,
	[ReciprocityAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LienCredit_Amount] [decimal](16, 2) NULL,
	[LienCredit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UpfrontTaxAssessedInLegacySystem] [bit] NULL,
	[IsActive] [bit] NULL
)
GO
