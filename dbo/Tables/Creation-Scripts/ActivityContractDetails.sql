SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityContractDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PaymentNumber] [int] NULL,
	[InitiatedTransactionEntityId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[ActivityForCustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TerminationReason] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[FullPayoff] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityContractDetails]  WITH CHECK ADD  CONSTRAINT [EActivityContractDetail_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ActivityContractDetails] CHECK CONSTRAINT [EActivityContractDetail_Contract]
GO
ALTER TABLE [dbo].[ActivityContractDetails]  WITH CHECK ADD  CONSTRAINT [EActivityForCustomer_ActivityContractDetails] FOREIGN KEY([ActivityForCustomerId])
REFERENCES [dbo].[ActivityForCustomers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityContractDetails] CHECK CONSTRAINT [EActivityForCustomer_ActivityContractDetails]
GO
