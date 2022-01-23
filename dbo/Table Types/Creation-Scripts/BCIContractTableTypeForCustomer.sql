CREATE TYPE [dbo].[BCIContractTableTypeForCustomer] AS TABLE(
	[ContractId] [bigint] NULL,
	[DueDate] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NULL
)
GO
