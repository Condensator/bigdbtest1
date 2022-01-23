SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeasePaymentSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentNumber] [int] NOT NULL,
	[DueDate] [date] NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [date] NOT NULL,
	[Disbursement_Amount] [decimal](16, 2) NOT NULL,
	[Disbursement_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentType] [nvarchar](28) COLLATE Latin1_General_CI_AS NULL,
	[BeginBalance_Amount] [decimal](16, 2) NOT NULL,
	[BeginBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EndBalance_Amount] [decimal](16, 2) NOT NULL,
	[EndBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Principal_Amount] [decimal](16, 2) NOT NULL,
	[Principal_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Interest_Amount] [decimal](16, 2) NOT NULL,
	[Interest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentStructure] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[Calculate] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableAdjustmentAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableAdjustmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActualPayment_Amount] [decimal](16, 2) NOT NULL,
	[ActualPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsRenewal] [bit] NOT NULL,
	[InterestAccrued_Amount] [decimal](16, 2) NOT NULL,
	[InterestAccrued_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeaseFinanceDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerId] [bigint] NULL,
	[VATAmount_Amount] [decimal](16, 2) NOT NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsVATProjected] [bit] NOT NULL,
	[Fee_Amount] [decimal](16, 2) NULL,
	[Fee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[VATonFee_Amount] [decimal](16, 2) NULL,
	[VATonFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeasePaymentSchedules]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_LeasePaymentSchedules] FOREIGN KEY([LeaseFinanceDetailId])
REFERENCES [dbo].[LeaseFinanceDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeasePaymentSchedules] CHECK CONSTRAINT [ELeaseFinanceDetail_LeasePaymentSchedules]
GO
ALTER TABLE [dbo].[LeasePaymentSchedules]  WITH CHECK ADD  CONSTRAINT [ELeasePaymentSchedule_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LeasePaymentSchedules] CHECK CONSTRAINT [ELeasePaymentSchedule_Customer]
GO
