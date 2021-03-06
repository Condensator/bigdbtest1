CREATE TYPE [dbo].[BlendedIncomeSchedule] AS TABLE(
	[IncomeDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Income_Amount] [decimal](16, 2) NOT NULL,
	[Income_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IncomeBalance_Amount] [decimal](16, 2) NOT NULL,
	[IncomeBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveYield] [decimal](28, 18) NULL,
	[EffectiveInterest_Amount] [decimal](16, 2) NULL,
	[EffectiveInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsAccounting] [bit] NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[ReversalPostDate] [date] NULL,
	[ModificationType] [nvarchar](31) COLLATE Latin1_General_CI_AS NULL,
	[ModificationId] [bigint] NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[AdjustmentEntry] [bit] NOT NULL,
	[IsRecomputed] [bit] NOT NULL,
	[LeaseFinanceId] [bigint] NULL,
	[LoanFinanceId] [bigint] NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
