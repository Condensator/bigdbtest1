SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EarliestDueDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EndDueDate] [date] NOT NULL,
	[DiscountRate] [decimal](14, 9) NULL,
	[PVOfCashInflow_Amount] [decimal](16, 2) NULL,
	[PVOfCashInflow_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BookedResidual_Amount] [decimal](16, 2) NULL,
	[BookedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalPaymentSold_Amount] [decimal](16, 2) NULL,
	[TotalPaymentSold_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[DiscountingFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IncludeResidual] [bit] NOT NULL,
	[ResidualBalance_Amount] [decimal](16, 2) NULL,
	[ResidualBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReleasedDate] [date] NULL,
	[PaidOffDate] [date] NULL,
	[PaidOffId] [bigint] NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[AdditionalPaymentSold_Amount] [decimal](16, 2) NULL,
	[AdditionalPaymentSold_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AdditionalBookedResidual_Amount] [decimal](16, 2) NULL,
	[AdditionalBookedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PVOfAdditionalCashInflow_Amount] [decimal](16, 2) NULL,
	[PVOfAdditionalCashInflow_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AmendmentDate] [date] NULL,
	[ResidualFactor] [decimal](18, 8) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingContracts]  WITH CHECK ADD  CONSTRAINT [EDiscountingContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[DiscountingContracts] CHECK CONSTRAINT [EDiscountingContract_Contract]
GO
ALTER TABLE [dbo].[DiscountingContracts]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingContracts] FOREIGN KEY([DiscountingFinanceId])
REFERENCES [dbo].[DiscountingFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingContracts] CHECK CONSTRAINT [EDiscountingFinance_DiscountingContracts]
GO
