CREATE TYPE [dbo].[LeaseBlendedItemMappingType] AS TABLE(
	[BlendedItemId] [bigint] NULL,
	[ParentBlendedItemId] [bigint] NULL,
	[Revise] [bit] NULL
)
GO
