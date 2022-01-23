CREATE TYPE [dbo].[AssetDetail] AS TABLE(
	[DateofProduction] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AgeofAsset] [decimal](16, 2) NOT NULL,
	[KW] [decimal](16, 2) NULL,
	[EngineCapacity] [decimal](16, 2) NULL,
	[ValueExclVAT_Amount] [decimal](16, 2) NOT NULL,
	[ValueExclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsVAT] [bit] NOT NULL,
	[ValueInclVAT_Amount] [decimal](16, 2) NOT NULL,
	[ValueInclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[MakeId] [bigint] NOT NULL,
	[ModelId] [bigint] NOT NULL,
	[TaxCodeId] [bigint] NOT NULL,
	[AssetClassConfigId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
