SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerACHAssignments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssignmentNumber] [bigint] NOT NULL,
	[PaymentType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[BankAccountId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RecurringPaymentMethod] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[DayoftheMonth] [int] NOT NULL,
	[RecurringACHPaymentRequestId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerACHAssignments]  WITH CHECK ADD  CONSTRAINT [ECustomer_CustomerACHAssignments] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CustomerACHAssignments] CHECK CONSTRAINT [ECustomer_CustomerACHAssignments]
GO
ALTER TABLE [dbo].[CustomerACHAssignments]  WITH CHECK ADD  CONSTRAINT [ECustomerACHAssignment_BankAccount] FOREIGN KEY([BankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[CustomerACHAssignments] CHECK CONSTRAINT [ECustomerACHAssignment_BankAccount]
GO
ALTER TABLE [dbo].[CustomerACHAssignments]  WITH CHECK ADD  CONSTRAINT [ECustomerACHAssignment_ReceivableType] FOREIGN KEY([ReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[CustomerACHAssignments] CHECK CONSTRAINT [ECustomerACHAssignment_ReceivableType]
GO
ALTER TABLE [dbo].[CustomerACHAssignments]  WITH CHECK ADD  CONSTRAINT [ECustomerACHAssignment_RecurringACHPaymentRequest] FOREIGN KEY([RecurringACHPaymentRequestId])
REFERENCES [dbo].[RecurringACHPaymentRequests] ([Id])
GO
ALTER TABLE [dbo].[CustomerACHAssignments] CHECK CONSTRAINT [ECustomerACHAssignment_RecurringACHPaymentRequest]
GO
