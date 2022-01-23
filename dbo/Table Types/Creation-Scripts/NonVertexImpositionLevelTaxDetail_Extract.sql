CREATE TYPE [dbo].[NonVertexImpositionLevelTaxDetail_Extract] AS TABLE(
	[ReceivableDetailId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NULL,
	[ImpositionType] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[JurisdictionLevel] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveRate] [decimal](10, 6) NOT NULL,
	[IsTaxExempt] [bit] NOT NULL,
	[TaxTypeId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
