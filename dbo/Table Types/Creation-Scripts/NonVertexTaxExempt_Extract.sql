CREATE TYPE [dbo].[NonVertexTaxExempt_Extract] AS TABLE(
	[AssetId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[IsCountryTaxExempt] [bit] NOT NULL,
	[IsStateTaxExempt] [bit] NOT NULL,
	[IsCountyTaxExempt] [bit] NOT NULL,
	[IsCityTaxExempt] [bit] NOT NULL,
	[CountryTaxExemptRule] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[StateTaxExemptRule] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CountyTaxExemptRule] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CityTaxExemptRule] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
