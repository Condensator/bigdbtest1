SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanLienFilings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LienFilingId] [bigint] NOT NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanLienFilings]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanLienFilings] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanLienFilings] CHECK CONSTRAINT [ELoanFinance_LoanLienFilings]
GO
ALTER TABLE [dbo].[LoanLienFilings]  WITH CHECK ADD  CONSTRAINT [ELoanLienFiling_LienFiling] FOREIGN KEY([LienFilingId])
REFERENCES [dbo].[LienFilings] ([Id])
GO
ALTER TABLE [dbo].[LoanLienFilings] CHECK CONSTRAINT [ELoanLienFiling_LienFiling]
GO
