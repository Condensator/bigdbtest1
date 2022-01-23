CREATE TYPE [dbo].[ServicingDetailsForReceivableUpdation] AS TABLE(
	[RemitToId] [bigint] NULL,
	[FromDate] [datetime] NULL,
	[ToDate] [datetime] NULL,
	[IsCollected] [bit] NULL,
	[DiscountingFinanceId] [bigint] NULL
)
GO
