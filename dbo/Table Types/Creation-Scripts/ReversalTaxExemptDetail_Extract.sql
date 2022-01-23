CREATE TYPE [dbo].[ReversalTaxExemptDetail_Extract] AS TABLE(
	[ReceivableDetailId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NULL,
	[CountryTaxExempt] [bit] NOT NULL,
	[StateTaxExempt] [bit] NOT NULL,
	[CityTaxExempt] [bit] NOT NULL,
	[CountyTaxExempt] [bit] NOT NULL,
	[CountryTaxExemptRule] [nvarchar](27) COLLATE Latin1_General_CI_AS NULL,
	[StateTaxExemptRule] [nvarchar](27) COLLATE Latin1_General_CI_AS NULL,
	[CityTaxExemptRule] [nvarchar](27) COLLATE Latin1_General_CI_AS NULL,
	[CountyTaxExemptRule] [nvarchar](27) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
