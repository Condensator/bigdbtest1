CREATE TYPE [dbo].[SalesTaxLocationDetail_Extract] AS TABLE(
	[LocationId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[City] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[StateShortName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CountryShortName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LocationStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[LocationCode] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxAreaEffectiveDate] [date] NULL,
	[IsVertexSupportedLocation] [bit] NOT NULL,
	[StateId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[AcquisitionLocationTaxAreaId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
