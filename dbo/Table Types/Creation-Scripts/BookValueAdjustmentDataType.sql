CREATE TYPE [dbo].[BookValueAdjustmentDataType] AS TABLE(
	[LegalEntityName] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetBookValueAdjustment_GL] [decimal](16, 2) NOT NULL,
	[AccumulatedImpairment_GL] [decimal](16, 2) NOT NULL,
	[AccumulatedAssetDepreciation_BVA_GL] [decimal](16, 2) NOT NULL,
	[AccumulatedAssetImpairment_BVA_GL] [decimal](16, 2) NOT NULL
)
GO
