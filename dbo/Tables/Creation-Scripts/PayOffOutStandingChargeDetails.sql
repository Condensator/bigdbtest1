SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayOffOutStandingChargeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DueDate] [date] NOT NULL,
	[ReceivableAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableBalance_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SalesTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[SalesTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SalesTaxBalance_Amount] [decimal](16, 2) NOT NULL,
	[SalesTaxBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableType] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[PayoffId] [bigint] NOT NULL,
	[IncludeinInvoice] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
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
ALTER TABLE [dbo].[PayOffOutStandingChargeDetails]  WITH CHECK ADD  CONSTRAINT [EPayoff_PayOffOutStandingChargeDetails] FOREIGN KEY([PayoffId])
REFERENCES [dbo].[Payoffs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayOffOutStandingChargeDetails] CHECK CONSTRAINT [EPayoff_PayOffOutStandingChargeDetails]
GO
ALTER TABLE [dbo].[PayOffOutStandingChargeDetails]  WITH CHECK ADD  CONSTRAINT [EPayOffOutStandingChargeDetail_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[PayOffOutStandingChargeDetails] CHECK CONSTRAINT [EPayOffOutStandingChargeDetail_Receivable]
GO
