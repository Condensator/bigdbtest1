SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanBlendedIncomeSummaryForReports](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BlendedItemCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BlendedItemName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Type] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[RecognitionMethod] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[BookRecognitionMode] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsAccumulatedExpense] [bit] NOT NULL,
	[IncludeInBlendedYield] [bit] NOT NULL,
	[IsFAS91] [bit] NOT NULL,
	[GeneratePayableOrReceivable] [bit] NOT NULL,
	[Occurrence] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Frequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[DueDate] [date] NULL,
	[RecurringNumber] [int] NOT NULL,
	[RecurringAmount_Amount] [decimal](16, 2) NOT NULL,
	[RecurringAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxRecognitionMode] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanBlendedIncomeSummaryForReports]  WITH CHECK ADD  CONSTRAINT [ELoanBlendedIncomeSummaryForReport_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LoanBlendedIncomeSummaryForReports] CHECK CONSTRAINT [ELoanBlendedIncomeSummaryForReport_Contract]
GO
