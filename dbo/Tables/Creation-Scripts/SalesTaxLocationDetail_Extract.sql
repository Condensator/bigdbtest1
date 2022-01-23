SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalesTaxLocationDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LocationId] [bigint] NOT NULL,
	[City] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[StateShortName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CountryShortName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LocationStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[LocationCode] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxAreaEffectiveDate] [date] NULL,
	[IsVertexSupportedLocation] [bit] NOT NULL,
	[StateId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AcquisitionLocationTaxAreaId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
