CREATE TYPE [dbo].[SyndicatedDealExposure] AS TABLE(
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityId] [bigint] NOT NULL,
	[SyndicatedLOCBalanceExposureRevolving_Amount] [decimal](24, 2) NOT NULL,
	[SyndicatedLOCBalanceExposureRevolving_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SyndicatedLOCBalanceExposureNonRevolving_Amount] [decimal](24, 2) NOT NULL,
	[SyndicatedLOCBalanceExposureNonRevolving_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SyndicatedContractExposure_Amount] [decimal](24, 2) NOT NULL,
	[SyndicatedContractExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalSyndicatedExposures_Amount] [decimal](24, 2) NOT NULL,
	[TotalSyndicatedExposures_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ExposureDate] [date] NULL,
	[OriginationVendorId] [bigint] NULL,
	[RNIId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
