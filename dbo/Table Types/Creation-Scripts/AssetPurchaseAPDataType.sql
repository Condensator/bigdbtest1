CREATE TYPE [dbo].[AssetPurchaseAPDataType] AS TABLE(
	[LegalEntityName] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[AcquisitionCost_GL] [decimal](16, 2) NOT NULL
)
GO
