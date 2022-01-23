SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NonVertexLocationDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LocationId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JurisdictionId] [bigint] NOT NULL,
	[StateId] [bigint] NOT NULL,
	[StateShortName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CountryId] [bigint] NOT NULL,
	[TaxBasisType] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[UpfrontTaxMode] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsCountryTaxExempt] [bit] NOT NULL,
	[IsStateTaxExempt] [bit] NOT NULL,
	[IsCountyTaxExempt] [bit] NOT NULL,
	[IsCityTaxExempt] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CountryShortName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
