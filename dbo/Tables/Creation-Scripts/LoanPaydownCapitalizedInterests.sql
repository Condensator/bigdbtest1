SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPaydownCapitalizedInterests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Source] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalizedDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayableInvoiceOtherCostId] [bigint] NULL,
	[LoanPaydownId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsBackUp] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPaydownCapitalizedInterests]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_LoanPaydownCapitalizedInterests] FOREIGN KEY([LoanPaydownId])
REFERENCES [dbo].[LoanPaydowns] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPaydownCapitalizedInterests] CHECK CONSTRAINT [ELoanPaydown_LoanPaydownCapitalizedInterests]
GO
ALTER TABLE [dbo].[LoanPaydownCapitalizedInterests]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownCapitalizedInterest_PayableInvoiceOtherCost] FOREIGN KEY([PayableInvoiceOtherCostId])
REFERENCES [dbo].[PayableInvoiceOtherCosts] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownCapitalizedInterests] CHECK CONSTRAINT [ELoanPaydownCapitalizedInterest_PayableInvoiceOtherCost]
GO
