CREATE TYPE [dbo].[ReceiptAllocation] AS TABLE(
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AllocationAmount_Amount] [decimal](16, 2) NOT NULL,
	[AllocationAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LegalEntityId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[ReceiptId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
