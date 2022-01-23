CREATE TYPE [dbo].[BlendedItemAsset] AS TABLE(
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxCredit_Amount] [decimal](16, 2) NOT NULL,
	[TaxCredit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UpfrontTaxReduction_Amount] [decimal](16, 2) NOT NULL,
	[UpfrontTaxReduction_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NewTaxBasis_Amount] [decimal](16, 2) NOT NULL,
	[NewTaxBasis_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BookBasis_Amount] [decimal](16, 2) NOT NULL,
	[BookBasis_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxCreditTaxBasisPercentage] [decimal](5, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LeaseAssetId] [bigint] NOT NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
