SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingAmendmentRepaymentSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AdjustmentEntry] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BeginBalance_Amount] [decimal](16, 2) NOT NULL,
	[BeginBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Calculate] [bit] NOT NULL,
	[DueDate] [date] NULL,
	[EndBalance_Amount] [decimal](16, 2) NOT NULL,
	[EndBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EndDate] [date] NULL,
	[GainLoss_Amount] [decimal](16, 2) NOT NULL,
	[GainLoss_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Interest_Amount] [decimal](16, 2) NOT NULL,
	[Interest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestProcessed_Amount] [decimal](16, 2) NOT NULL,
	[InterestProcessed_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentNumber] [int] NOT NULL,
	[PaymentStructure] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[PaymentType] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[Principal_Amount] [decimal](16, 2) NOT NULL,
	[Principal_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrincipalProcessed_Amount] [decimal](16, 2) NOT NULL,
	[PrincipalProcessed_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[StartDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[DiscountingAmendmentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingAmendmentRepaymentSchedules]  WITH CHECK ADD  CONSTRAINT [EDiscountingAmendment_DiscountingAmendmentRepaymentSchedules] FOREIGN KEY([DiscountingAmendmentId])
REFERENCES [dbo].[DiscountingAmendments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingAmendmentRepaymentSchedules] CHECK CONSTRAINT [EDiscountingAmendment_DiscountingAmendmentRepaymentSchedules]
GO
