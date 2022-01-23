CREATE TYPE [dbo].[LegalEntityBankInfoForACHUpdate] AS TABLE(
	[LegalEntityId] [bigint] NULL,
	[BankAccountId] [bigint] NULL,
	[UpdatedProcessThroughDateForACH] [date] NULL,
	[UpdatedSettlementDateForACH] [date] NULL,
	[UpdatedProcessThroughDateForOTACH] [date] NULL,
	[UpdatedSettlementDateForOTACH] [date] NULL,
	[NextWorkingDate] [datetimeoffset](7) NULL,
	[CurrencyId] [bigint] NULL
)
GO
