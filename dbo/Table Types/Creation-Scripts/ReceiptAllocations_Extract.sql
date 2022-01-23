CREATE TYPE [dbo].[ReceiptAllocations_Extract] AS TABLE(
	[ReceiptId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[AllocationAmount] [decimal](16, 2) NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[InvoiceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[IsStatementInvoiceCalculationRequired] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
