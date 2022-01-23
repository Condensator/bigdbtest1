CREATE TYPE [dbo].[BlendedItemsToUpdateEndDate] AS TABLE(
	[CurrentEndDate] [date] NULL,
	[BlendedItemId] [bigint] NULL,
	[EndDate] [date] NULL
)
GO
