CREATE TYPE [dbo].[WHTWaiverReceivableDetailsInfo] AS TABLE(
	[ReceivableDetailId] [bigint] NOT NULL,
	[AdjustedWHTAmount] [decimal](16, 2) NOT NULL
)
GO
