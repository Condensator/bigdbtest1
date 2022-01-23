CREATE TYPE [dbo].[NonVertexLocationDetail_Extract] AS TABLE(
	[LocationId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JurisdictionId] [bigint] NOT NULL,
	[StateId] [bigint] NOT NULL,
	[StateShortName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CountryShortName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CountryId] [bigint] NOT NULL,
	[TaxBasisType] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[UpfrontTaxMode] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsCountryTaxExempt] [bit] NOT NULL,
	[IsStateTaxExempt] [bit] NOT NULL,
	[IsCountyTaxExempt] [bit] NOT NULL,
	[IsCityTaxExempt] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
