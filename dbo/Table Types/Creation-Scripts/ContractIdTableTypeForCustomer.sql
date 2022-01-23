CREATE TYPE [dbo].[ContractIdTableTypeForCustomer] AS TABLE(
	[ContractId] [bigint] NULL,
	[DiscountingId] [bigint] NULL,
	[DueDate] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NULL,
	[ReceivableStartId] [bigint] NULL,
	[ReceivableEndId] [bigint] NULL
)
GO
