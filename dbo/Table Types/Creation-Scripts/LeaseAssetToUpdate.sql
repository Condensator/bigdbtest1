CREATE TYPE [dbo].[LeaseAssetToUpdate] AS TABLE(
	[Id] [bigint] NULL,
	[FxTaxBasisAmount_Amount] [decimal](16, 2) NULL,
	[FxTaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL
)
GO
