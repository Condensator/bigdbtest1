CREATE TYPE [dbo].[AssetUpdate_AssetData] AS TABLE(
	[PayoffId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[Status] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerId] [bigint] NULL,
	[BookDepGLTemplateId] [bigint] NULL,
	[TaxDepDisposalTemplateId] [bigint] NULL,
	[PayOffAmount] [decimal](16, 2) NOT NULL,
	[IsTaxDepEntityUpdateApplicable] [bit] NULL
)
GO
