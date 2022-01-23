SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractAssumptionHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssumptionDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BillToId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[FinanceId] [bigint] NOT NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractAssumptionHistories]  WITH CHECK ADD  CONSTRAINT [EContract_ContractAssumptionHistories] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractAssumptionHistories] CHECK CONSTRAINT [EContract_ContractAssumptionHistories]
GO
ALTER TABLE [dbo].[ContractAssumptionHistories]  WITH CHECK ADD  CONSTRAINT [EContractAssumptionHistory_Assumption] FOREIGN KEY([AssumptionId])
REFERENCES [dbo].[Assumptions] ([Id])
GO
ALTER TABLE [dbo].[ContractAssumptionHistories] CHECK CONSTRAINT [EContractAssumptionHistory_Assumption]
GO
ALTER TABLE [dbo].[ContractAssumptionHistories]  WITH CHECK ADD  CONSTRAINT [EContractAssumptionHistory_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[ContractAssumptionHistories] CHECK CONSTRAINT [EContractAssumptionHistory_BillTo]
GO
ALTER TABLE [dbo].[ContractAssumptionHistories]  WITH CHECK ADD  CONSTRAINT [EContractAssumptionHistory_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[ContractAssumptionHistories] CHECK CONSTRAINT [EContractAssumptionHistory_Customer]
GO
