SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NonVertexLeaseDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
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
	[RowVersion] [timestamp] NOT NULL,
	[SalesTaxRemittanceMethod] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
