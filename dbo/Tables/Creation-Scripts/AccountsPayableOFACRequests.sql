SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccountsPayableOFACRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OFACRequestId] [bigint] NOT NULL,
	[AccountsPayablePaymentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AccountsPayableOFACRequests]  WITH CHECK ADD  CONSTRAINT [EAccountsPayableOFACRequest_OFACRequest] FOREIGN KEY([OFACRequestId])
REFERENCES [dbo].[OFACRequests] ([Id])
GO
ALTER TABLE [dbo].[AccountsPayableOFACRequests] CHECK CONSTRAINT [EAccountsPayableOFACRequest_OFACRequest]
GO
ALTER TABLE [dbo].[AccountsPayableOFACRequests]  WITH CHECK ADD  CONSTRAINT [EAccountsPayablePayment_AccountsPayableOFACRequests] FOREIGN KEY([AccountsPayablePaymentId])
REFERENCES [dbo].[AccountsPayablePayments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AccountsPayableOFACRequests] CHECK CONSTRAINT [EAccountsPayablePayment_AccountsPayableOFACRequests]
GO
