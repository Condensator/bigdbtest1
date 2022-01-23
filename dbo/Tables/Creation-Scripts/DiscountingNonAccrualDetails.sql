SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingNonAccrualDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[NonAccrualDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[LastPaymentDate] [date] NULL,
	[LastExpenseUpdateDate] [date] NULL,
	[NBV_Amount] [decimal](16, 2) NOT NULL,
	[NBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NBVPostAdjustments_Amount] [decimal](16, 2) NOT NULL,
	[NBVPostAdjustments_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalOutstandingPayment_Amount] [decimal](16, 2) NOT NULL,
	[TotalOutstandingPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExpenseRecognizedAfterNonAccrual_Amount] [decimal](16, 2) NOT NULL,
	[ExpenseRecognizedAfterNonAccrual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DiscountingId] [bigint] NOT NULL,
	[DiscountingNonAccrualId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[APTemplateId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingNonAccrualDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingNonAccrual_DiscountingNonAccrualDetails] FOREIGN KEY([DiscountingNonAccrualId])
REFERENCES [dbo].[DiscountingNonAccruals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingNonAccrualDetails] CHECK CONSTRAINT [EDiscountingNonAccrual_DiscountingNonAccrualDetails]
GO
ALTER TABLE [dbo].[DiscountingNonAccrualDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingNonAccrualDetail_APTemplate] FOREIGN KEY([APTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[DiscountingNonAccrualDetails] CHECK CONSTRAINT [EDiscountingNonAccrualDetail_APTemplate]
GO
ALTER TABLE [dbo].[DiscountingNonAccrualDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingNonAccrualDetail_Discounting] FOREIGN KEY([DiscountingId])
REFERENCES [dbo].[Discountings] ([Id])
GO
ALTER TABLE [dbo].[DiscountingNonAccrualDetails] CHECK CONSTRAINT [EDiscountingNonAccrualDetail_Discounting]
GO
