CREATE TYPE [dbo].[MoneyDistributiveListType] AS TABLE(
	[RowNumber] [bigint] NULL,
	[EntityId] [bigint] NULL,
	[Amount] [decimal](16, 2) NULL
)
GO
