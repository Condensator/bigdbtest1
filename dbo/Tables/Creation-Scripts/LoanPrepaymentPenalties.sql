SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPrepaymentPenalties](
	[Id] [bigint] NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PrepaymentBasis] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[MinimumPrepaymentMonths] [int] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PrepaymentPenaltyTerm] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPrepaymentPenalties]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanPrepaymentPenalty] FOREIGN KEY([Id])
REFERENCES [dbo].[LoanFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPrepaymentPenalties] CHECK CONSTRAINT [ELoanFinance_LoanPrepaymentPenalty]
GO
