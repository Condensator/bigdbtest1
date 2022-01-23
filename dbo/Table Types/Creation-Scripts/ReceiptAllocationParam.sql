CREATE TYPE [dbo].[ReceiptAllocationParam] AS TABLE(
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[AllocationAmount] [decimal](16, 2) NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AmountApplied] [decimal](16, 2) NULL,
	[IsActive] [bit] NULL,
	[LegalEntityId] [bigint] NULL,
	[ContractId] [bigint] NULL
)
GO
