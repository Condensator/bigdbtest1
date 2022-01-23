SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingPaydownContractDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Release] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TotalPaymentSold_Amount] [decimal](16, 2) NULL,
	[TotalPaymentSold_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DiscountingContractId] [bigint] NULL,
	[DiscountingPaydownId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[BookedResidual_Amount] [decimal](16, 2) NULL,
	[BookedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AccountResidualBalanceToGainLoss] [bit] NOT NULL,
	[ResidualGainLoss_Amount] [decimal](16, 2) NOT NULL,
	[ResidualGainLoss_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ResidualPayable_Amount] [decimal](16, 2) NOT NULL,
	[ResidualPayable_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingPaydownContractDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydown_DiscountingPaydownContractDetails] FOREIGN KEY([DiscountingPaydownId])
REFERENCES [dbo].[DiscountingPaydowns] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingPaydownContractDetails] CHECK CONSTRAINT [EDiscountingPaydown_DiscountingPaydownContractDetails]
GO
ALTER TABLE [dbo].[DiscountingPaydownContractDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingPaydownContractDetail_DiscountingContract] FOREIGN KEY([DiscountingContractId])
REFERENCES [dbo].[DiscountingContracts] ([Id])
GO
ALTER TABLE [dbo].[DiscountingPaydownContractDetails] CHECK CONSTRAINT [EDiscountingPaydownContractDetail_DiscountingContract]
GO
