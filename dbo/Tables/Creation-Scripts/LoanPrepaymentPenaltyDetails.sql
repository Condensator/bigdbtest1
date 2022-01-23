SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPrepaymentPenaltyDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FromMonth] [int] NULL,
	[ToMonth] [int] NULL,
	[Percentage] [decimal](5, 2) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LoanPrepaymentPenaltyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RowNumber] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPrepaymentPenaltyDetails]  WITH CHECK ADD  CONSTRAINT [ELoanPrepaymentPenalty_LoanPrepaymentPenaltyDetails] FOREIGN KEY([LoanPrepaymentPenaltyId])
REFERENCES [dbo].[LoanPrepaymentPenalties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPrepaymentPenaltyDetails] CHECK CONSTRAINT [ELoanPrepaymentPenalty_LoanPrepaymentPenaltyDetails]
GO
