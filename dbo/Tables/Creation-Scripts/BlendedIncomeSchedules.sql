SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BlendedIncomeSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IncomeDate] [date] NULL,
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
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeaseFinanceId] [bigint] NULL,
	[LoanFinanceId] [bigint] NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsRecomputed] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BlendedIncomeSchedules]  WITH CHECK ADD  CONSTRAINT [EBlendedIncomeSchedule_BlendedItem] FOREIGN KEY([BlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[BlendedIncomeSchedules] CHECK CONSTRAINT [EBlendedIncomeSchedule_BlendedItem]
GO
ALTER TABLE [dbo].[BlendedIncomeSchedules]  WITH CHECK ADD  CONSTRAINT [EBlendedIncomeSchedule_LeaseFinance] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
GO
ALTER TABLE [dbo].[BlendedIncomeSchedules] CHECK CONSTRAINT [EBlendedIncomeSchedule_LeaseFinance]
GO
ALTER TABLE [dbo].[BlendedIncomeSchedules]  WITH CHECK ADD  CONSTRAINT [EBlendedIncomeSchedule_LoanFinance] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
GO
ALTER TABLE [dbo].[BlendedIncomeSchedules] CHECK CONSTRAINT [EBlendedIncomeSchedule_LoanFinance]
GO
