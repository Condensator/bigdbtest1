CREATE TYPE [dbo].[AssetTypeTaxDepreciation] AS TABLE(
	[EffectiveDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[CountryId] [bigint] NOT NULL,
	[DomesticTaxDepTemplateId] [bigint] NULL,
	[InternationalTaxDepTemplateId] [bigint] NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
