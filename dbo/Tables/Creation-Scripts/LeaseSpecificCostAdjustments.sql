SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseSpecificCostAdjustments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[CapitalizeFrom] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayableInvoiceOtherCostId] [bigint] NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseSpecificCostAdjustments]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LeaseSpecificCostAdjustments] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseSpecificCostAdjustments] CHECK CONSTRAINT [ELeaseFinance_LeaseSpecificCostAdjustments]
GO
ALTER TABLE [dbo].[LeaseSpecificCostAdjustments]  WITH CHECK ADD  CONSTRAINT [ELeaseSpecificCostAdjustment_PayableInvoiceOtherCost] FOREIGN KEY([PayableInvoiceOtherCostId])
REFERENCES [dbo].[PayableInvoiceOtherCosts] ([Id])
GO
ALTER TABLE [dbo].[LeaseSpecificCostAdjustments] CHECK CONSTRAINT [ELeaseSpecificCostAdjustment_PayableInvoiceOtherCost]
GO
