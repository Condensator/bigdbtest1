CREATE TYPE [dbo].[PropertyTaxContractSettings] AS TABLE(
	[UniqueIdentifier] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeaseContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsBankQualified] [bit] NOT NULL,
	[IsFederalIncomeTaxExempt] [bit] NOT NULL,
	[EffectiveFromDate] [date] NOT NULL,
	[EffectiveToDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[PropertyTaxParameterId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
