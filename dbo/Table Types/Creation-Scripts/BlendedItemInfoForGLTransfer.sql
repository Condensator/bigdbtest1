CREATE TYPE [dbo].[BlendedItemInfoForGLTransfer] AS TABLE(
	[ContractId] [bigint] NULL,
	[BlendedItemId] [bigint] NULL,
	[IncomeGLPostedTillDate] [date] NULL,
	[IsReceivableForTransferBlendedItem] [bit] NULL,
	[IsChargedOffContract] [bit] NULL
)
GO
