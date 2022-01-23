SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPaydownBlendedItems](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PaydownCostAdjustment_Amount] [decimal](16, 2) NOT NULL,
	[PaydownCostAdjustment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccumulatedAdjustment_Amount] [decimal](16, 2) NOT NULL,
	[AccumulatedAdjustment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EarnedAmount_Amount] [decimal](16, 2) NOT NULL,
	[EarnedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UnearnedAmount_Amount] [decimal](16, 2) NOT NULL,
	[UnearnedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BilledAmount_Amount] [decimal](16, 2) NOT NULL,
	[BilledAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmountToBeBilled_Amount] [decimal](16, 2) NOT NULL,
	[AmountToBeBilled_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[OriginalBlendedItemEndDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BlendedItemId] [bigint] NULL,
	[LoanPaydownId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[EffectiveInterest_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPaydownBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_LoanPaydownBlendedItems] FOREIGN KEY([LoanPaydownId])
REFERENCES [dbo].[LoanPaydowns] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPaydownBlendedItems] CHECK CONSTRAINT [ELoanPaydown_LoanPaydownBlendedItems]
GO
ALTER TABLE [dbo].[LoanPaydownBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownBlendedItem_BlendedItem] FOREIGN KEY([BlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownBlendedItems] CHECK CONSTRAINT [ELoanPaydownBlendedItem_BlendedItem]
GO
