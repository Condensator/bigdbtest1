CREATE TYPE [dbo].[ReceivableForTransferBlendedItemDetail] AS TABLE(
	[BlendedItemId] [bigint] NULL,
	[ToBeInactivated] [bit] NULL,
	[NewEndDate] [datetime] NULL
)
GO
