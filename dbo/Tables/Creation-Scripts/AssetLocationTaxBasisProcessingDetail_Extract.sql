SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetLocationTaxBasisProcessingDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[City] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Country] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NOT NULL,
	[LeaseType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[LeaseUniqueID] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NULL,
	[Company] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Currency] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[ToState] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetId] [bigint] NULL,
	[LineItemId] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[LocationId] [bigint] NOT NULL,
	[ContractType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[CustomerNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxAreaId] [bigint] NOT NULL,
	[AssetLocationId] [bigint] NOT NULL,
	[BatchId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LegalEntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[LocationCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
