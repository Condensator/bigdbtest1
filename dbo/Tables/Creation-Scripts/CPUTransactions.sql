SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUTransactions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReferenceNumber] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[TransactionType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[CPUContractId] [bigint] NOT NULL,
	[CPUFinanceId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[InActiveReason] [nvarchar](22) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUTransactions]  WITH CHECK ADD  CONSTRAINT [ECPUTransaction_CPUContract] FOREIGN KEY([CPUContractId])
REFERENCES [dbo].[CPUContracts] ([Id])
GO
ALTER TABLE [dbo].[CPUTransactions] CHECK CONSTRAINT [ECPUTransaction_CPUContract]
GO
ALTER TABLE [dbo].[CPUTransactions]  WITH CHECK ADD  CONSTRAINT [ECPUTransaction_CPUFinance] FOREIGN KEY([CPUFinanceId])
REFERENCES [dbo].[CPUFinances] ([Id])
GO
ALTER TABLE [dbo].[CPUTransactions] CHECK CONSTRAINT [ECPUTransaction_CPUFinance]
GO
