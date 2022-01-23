CREATE TYPE [dbo].[TaxDepRate] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Country] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[System] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Method] [nvarchar](34) COLLATE Latin1_General_CI_AS NOT NULL,
	[RecoveryPeriod] [decimal](3, 1) NOT NULL,
	[PropertyClassNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[TaxDepreciationConventionId] [bigint] NOT NULL,
	[CapitalCostAllowanceClassId] [bigint] NULL,
	[SpecifiedInterestRateIndexId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
