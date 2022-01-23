SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NonAccrualContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[NonAccrualDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[NBV_Amount] [decimal](16, 2) NOT NULL,
	[NBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NBVWithBlended_Amount] [decimal](16, 2) NOT NULL,
	[NBVWithBlended_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalOutstandingAR_Amount] [decimal](16, 2) NOT NULL,
	[TotalOutstandingAR_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccountingDate] [date] NULL,
	[LastReceiptDate] [date] NULL,
	[IncomeRecognizedAfterNonAccrual_Amount] [decimal](16, 2) NOT NULL,
	[IncomeRecognizedAfterNonAccrual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BillingSuppressed] [bit] NOT NULL,
	[DeferredRentalIncomeReclass_Amount] [decimal](16, 2) NOT NULL,
	[DeferredRentalIncomeReclass_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LastIncomeUpdateDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[NonAccrualId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DoubtfulCollectability] [bit] NOT NULL,
	[IsNonAccrualApproved] [bit] NOT NULL,
	[PostDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[NonAccrualContracts]  WITH CHECK ADD  CONSTRAINT [ENonAccrual_NonAccrualContracts] FOREIGN KEY([NonAccrualId])
REFERENCES [dbo].[NonAccruals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[NonAccrualContracts] CHECK CONSTRAINT [ENonAccrual_NonAccrualContracts]
GO
ALTER TABLE [dbo].[NonAccrualContracts]  WITH CHECK ADD  CONSTRAINT [ENonAccrualContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[NonAccrualContracts] CHECK CONSTRAINT [ENonAccrualContract_Contract]
GO
