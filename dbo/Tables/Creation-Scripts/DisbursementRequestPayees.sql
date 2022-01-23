SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DisbursementRequestPayees](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ApprovedAmount_Amount] [decimal](16, 2) NOT NULL,
	[ApprovedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivablesApplied_Amount] [decimal](16, 2) NOT NULL,
	[ReceivablesApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PaidAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaidAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayeeId] [bigint] NOT NULL,
	[DisbursementRequestPayableId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DisbursementRequestPayees]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequestPayable_DisbursementRequestPayees] FOREIGN KEY([DisbursementRequestPayableId])
REFERENCES [dbo].[DisbursementRequestPayables] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DisbursementRequestPayees] CHECK CONSTRAINT [EDisbursementRequestPayable_DisbursementRequestPayees]
GO
ALTER TABLE [dbo].[DisbursementRequestPayees]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequestPayee_Payee] FOREIGN KEY([PayeeId])
REFERENCES [dbo].[DisbursementRequestPaymentDetails] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequestPayees] CHECK CONSTRAINT [EDisbursementRequestPayee_Payee]
GO
