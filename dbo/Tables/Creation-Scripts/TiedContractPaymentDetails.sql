SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TiedContractPaymentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SharedAmount_Amount] [decimal](16, 2) NOT NULL,
	[SharedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaymentScheduleId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[DiscountingRepaymentScheduleId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TiedContractPaymentDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingRepaymentSchedule_TiedContractPaymentDetails] FOREIGN KEY([DiscountingRepaymentScheduleId])
REFERENCES [dbo].[DiscountingRepaymentSchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TiedContractPaymentDetails] CHECK CONSTRAINT [EDiscountingRepaymentSchedule_TiedContractPaymentDetails]
GO
ALTER TABLE [dbo].[TiedContractPaymentDetails]  WITH CHECK ADD  CONSTRAINT [ETiedContractPaymentDetail_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[TiedContractPaymentDetails] CHECK CONSTRAINT [ETiedContractPaymentDetail_Contract]
GO
