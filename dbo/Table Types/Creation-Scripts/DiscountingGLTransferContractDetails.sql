CREATE TYPE [dbo].[DiscountingGLTransferContractDetails] AS TABLE(
	[DiscountingId] [bigint] NULL,
	[DiscountingFinanceId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[IsLegalEntityChanged] [bit] NULL,
	[BranchId] [bigint] NULL
)
GO
