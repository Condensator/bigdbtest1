SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptPostByDSLDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[UpdateRunTillDate] [date] NULL,
	[PrincipalBalance_Amount] [decimal](16, 2) NULL,
	[PrincipalBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestRemaining_Amount] [decimal](16, 2) NULL,
	[InterestRemaining_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PrincipalRemaining_Amount] [decimal](16, 2) NULL,
	[PrincipalRemaining_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AccruedInterest_Amount] [decimal](16, 2) NULL,
	[AccruedInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PrincipalAmount_Amount] [decimal](16, 2) NULL,
	[PrincipalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestAmount_Amount] [decimal](16, 2) NULL,
	[InterestAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[ReceiptId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptPostByDSLDetails]  WITH CHECK ADD  CONSTRAINT [EReceipt_ReceiptPostByDSLDetails] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceiptPostByDSLDetails] CHECK CONSTRAINT [EReceipt_ReceiptPostByDSLDetails]
GO
ALTER TABLE [dbo].[ReceiptPostByDSLDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptPostByDSLDetail_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ReceiptPostByDSLDetails] CHECK CONSTRAINT [EReceiptPostByDSLDetail_Contract]
GO
