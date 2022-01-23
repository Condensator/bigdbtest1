SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccountsPayableOFACHits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OFACHitId] [bigint] NOT NULL,
	[AccountsPayablePaymentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AccountsPayableOFACHits]  WITH CHECK ADD  CONSTRAINT [EAccountsPayableOFACHit_OFACHit] FOREIGN KEY([OFACHitId])
REFERENCES [dbo].[OFACHits] ([Id])
GO
ALTER TABLE [dbo].[AccountsPayableOFACHits] CHECK CONSTRAINT [EAccountsPayableOFACHit_OFACHit]
GO
ALTER TABLE [dbo].[AccountsPayableOFACHits]  WITH CHECK ADD  CONSTRAINT [EAccountsPayablePayment_AccountsPayableOFACHits] FOREIGN KEY([AccountsPayablePaymentId])
REFERENCES [dbo].[AccountsPayablePayments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AccountsPayableOFACHits] CHECK CONSTRAINT [EAccountsPayablePayment_AccountsPayableOFACHits]
GO
