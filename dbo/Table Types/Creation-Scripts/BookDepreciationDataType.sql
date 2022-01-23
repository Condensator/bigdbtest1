CREATE TYPE [dbo].[BookDepreciationDataType] AS TABLE(
	[LegalEntityName] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccumulatedAssetDepreciation_BD_GL] [decimal](16, 2) NOT NULL
)
GO
