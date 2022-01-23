CREATE TYPE [dbo].[AssetLocation] AS TABLE(
	[EffectiveFromDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsCurrent] [bit] NOT NULL,
	[UpfrontTaxMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[IsFLStampTaxExempt] [bit] NOT NULL,
	[ReciprocityAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReciprocityAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LienCredit_Amount] [decimal](16, 2) NOT NULL,
	[LienCredit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpfrontTaxAssessedInLegacySystem] [bit] NOT NULL,
	[LocationId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
