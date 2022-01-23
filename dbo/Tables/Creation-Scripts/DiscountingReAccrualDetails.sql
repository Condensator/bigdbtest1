SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingReAccrualDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReAccrualDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[NBV_Amount] [decimal](16, 2) NOT NULL,
	[NBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NBVPostAdjustments_Amount] [decimal](16, 2) NOT NULL,
	[NBVPostAdjustments_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalOutstandingPayment_Amount] [decimal](16, 2) NOT NULL,
	[TotalOutstandingPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LastPaymentDate] [date] NULL,
	[SuspendedExpense_Amount] [decimal](16, 2) NOT NULL,
	[SuspendedExpense_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonAccrualDate] [date] NULL,
	[LastExpenseUpdateDate] [date] NULL,
	[DiscountingId] [bigint] NOT NULL,
	[DiscountingReAccrualId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingReAccrualDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingReAccrual_DiscountingReAccrualDetails] FOREIGN KEY([DiscountingReAccrualId])
REFERENCES [dbo].[DiscountingReAccruals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingReAccrualDetails] CHECK CONSTRAINT [EDiscountingReAccrual_DiscountingReAccrualDetails]
GO
ALTER TABLE [dbo].[DiscountingReAccrualDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingReAccrualDetail_Discounting] FOREIGN KEY([DiscountingId])
REFERENCES [dbo].[Discountings] ([Id])
GO
ALTER TABLE [dbo].[DiscountingReAccrualDetails] CHECK CONSTRAINT [EDiscountingReAccrualDetail_Discounting]
GO
