CREATE TYPE [dbo].[LeaseInput_LeaseIncomeAdjustment] AS TABLE(
	[ContractId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[AdjustmentStartDate] [date] NOT NULL
)
GO
