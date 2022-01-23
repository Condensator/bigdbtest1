CREATE TYPE [dbo].[DefTaxContractDetailTableType] AS TABLE(
	[ContractId] [bigint] NULL,
	[DueDate] [date] NULL,
	[IsToDeactivateDefTax] [bit] NULL
)
GO
