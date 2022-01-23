SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReAccrualContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReAccrualDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[NBV_Amount] [decimal](16, 2) NOT NULL,
	[NBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NBVWithBlended_Amount] [decimal](16, 2) NOT NULL,
	[NBVWithBlended_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalOutstandingAR_Amount] [decimal](16, 2) NOT NULL,
	[TotalOutstandingAR_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccountingDate] [date] NULL,
	[LastReceiptDate] [date] NULL,
	[SuspendedIncome_Amount] [decimal](16, 2) NOT NULL,
	[SuspendedIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ResumeBilling] [bit] NOT NULL,
	[NonAccrualDate] [date] NULL,
	[LastIncomeUpdateDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[ReAccrualId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReAccrualContracts]  WITH CHECK ADD  CONSTRAINT [EReAccrual_ReAccrualContracts] FOREIGN KEY([ReAccrualId])
REFERENCES [dbo].[ReAccruals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReAccrualContracts] CHECK CONSTRAINT [EReAccrual_ReAccrualContracts]
GO
ALTER TABLE [dbo].[ReAccrualContracts]  WITH CHECK ADD  CONSTRAINT [EReAccrualContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ReAccrualContracts] CHECK CONSTRAINT [EReAccrualContract_Contract]
GO
