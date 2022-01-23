CREATE TYPE [dbo].[AdjustmentPayableInfo] AS TABLE(
	[OldPayableId] [bigint] NOT NULL,
	[Amount] [decimal](16, 2) NOT NULL,
	[Balance] [decimal](16, 2) NOT NULL,
	[PayableStatus] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL
)
GO
