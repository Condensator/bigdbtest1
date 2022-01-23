CREATE TYPE [dbo].[AssetHistory] AS TABLE(
	[Reason] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AsOfDate] [date] NOT NULL,
	[AcquisitionDate] [date] NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[FinancialType] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceModule] [nvarchar](22) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceModuleId] [bigint] NOT NULL,
	[IsReversed] [bit] NOT NULL,
	[CustomerId] [bigint] NULL,
	[ParentAssetId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[ContractId] [bigint] NULL,
	[AssetId] [bigint] NOT NULL,
	[PropertyTaxReportCodeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
