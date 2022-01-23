CREATE TYPE [dbo].[CostConfiguration] AS TABLE(
	[BreakdownAmount_Amount] [decimal](16, 2) NOT NULL,
	[BreakdownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AdjustmentFactor] [decimal](18, 8) NOT NULL,
	[AdjustmentAmount_Amount] [decimal](16, 2) NOT NULL,
	[AdjustmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CostTypeId] [bigint] NOT NULL,
	[CreditDecisionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
