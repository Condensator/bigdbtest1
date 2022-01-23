CREATE TYPE [dbo].[BlendedItemDetailValuesForLoan] AS TABLE(
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Amount] [decimal](16, 2) NULL,
	[DueDate] [date] NULL,
	[BlendedItemId] [bigint] NULL
)
GO
