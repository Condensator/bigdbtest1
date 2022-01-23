SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NonVertexTaxExempt_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetId] [bigint] NULL,
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
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
