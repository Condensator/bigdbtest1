CREATE TYPE [dbo].[GLTransferContractDetails] AS TABLE(
	[ContractId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
	[LoanFinanceId] [bigint] NULL,
	[NewFinanceId] [bigint] NULL,
	[LeveragedLeaseId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[AcquisitionId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[RemitToId] [bigint] NULL,
	[ContractType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsLegalEntityChanged] [bit] NULL,
	[BranchId] [bigint] NULL,
	[IncomeDate] [datetime] NULL
)
GO
