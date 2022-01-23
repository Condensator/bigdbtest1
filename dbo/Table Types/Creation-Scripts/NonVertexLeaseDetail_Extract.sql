CREATE TYPE [dbo].[NonVertexLeaseDetail_Extract] AS TABLE(
	[LeaseFinanceId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[IsCountryTaxExempt] [bit] NOT NULL,
	[IsStateTaxExempt] [bit] NOT NULL,
	[IsCountyTaxExempt] [bit] NOT NULL,
	[IsCityTaxExempt] [bit] NOT NULL,
	[IsContractCapitalizeUpfront] [bit] NOT NULL,
	[IsLease] [bit] NOT NULL,
	[IsSyndicated] [bit] NOT NULL,
	[CommencementDate] [date] NULL,
	[NumberOfInceptionPayments] [int] NOT NULL,
	[ClassificationContractType] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[SalesTaxRemittanceMethod] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
