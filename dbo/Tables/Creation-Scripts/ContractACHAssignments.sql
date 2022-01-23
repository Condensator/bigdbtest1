SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractACHAssignments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssignmentNumber] [bigint] NOT NULL,
	[BeginDate] [date] NULL,
	[EndDate] [date] NULL,
	[PaymentType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableTypeId] [bigint] NULL,
	[BankAccountId] [bigint] NULL,
	[ContractBillingId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RecurringPaymentMethod] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[DayoftheMonth] [int] NOT NULL,
	[RecurringACHPaymentRequestId] [bigint] NULL,
	[IsEndPaymentOnMaturity] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractACHAssignments]  WITH CHECK ADD  CONSTRAINT [EContractACHAssignment_BankAccount] FOREIGN KEY([BankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[ContractACHAssignments] CHECK CONSTRAINT [EContractACHAssignment_BankAccount]
GO
ALTER TABLE [dbo].[ContractACHAssignments]  WITH CHECK ADD  CONSTRAINT [EContractACHAssignment_ReceivableType] FOREIGN KEY([ReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[ContractACHAssignments] CHECK CONSTRAINT [EContractACHAssignment_ReceivableType]
GO
ALTER TABLE [dbo].[ContractACHAssignments]  WITH CHECK ADD  CONSTRAINT [EContractACHAssignment_RecurringACHPaymentRequest] FOREIGN KEY([RecurringACHPaymentRequestId])
REFERENCES [dbo].[RecurringACHPaymentRequests] ([Id])
GO
ALTER TABLE [dbo].[ContractACHAssignments] CHECK CONSTRAINT [EContractACHAssignment_RecurringACHPaymentRequest]
GO
ALTER TABLE [dbo].[ContractACHAssignments]  WITH CHECK ADD  CONSTRAINT [EContractBilling_ContractACHAssignments] FOREIGN KEY([ContractBillingId])
REFERENCES [dbo].[ContractBillings] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractACHAssignments] CHECK CONSTRAINT [EContractBilling_ContractACHAssignments]
GO
