SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EscrowAccountFunders](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FundingFor] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FundingAmount_Amount] [decimal](16, 2) NULL,
	[FundingAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DisbursementType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DisbursementNumber] [bigint] NULL,
	[InvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PayeeName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[FederalReferenceNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[FinalFunding] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EscrowAccountId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EscrowAccountFunders]  WITH CHECK ADD  CONSTRAINT [EEscrowAccount_EscrowAccountFunders] FOREIGN KEY([EscrowAccountId])
REFERENCES [dbo].[EscrowAccounts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EscrowAccountFunders] CHECK CONSTRAINT [EEscrowAccount_EscrowAccountFunders]
GO
