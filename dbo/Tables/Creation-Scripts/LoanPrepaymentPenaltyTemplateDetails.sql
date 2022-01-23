SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPrepaymentPenaltyTemplateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FromMonth] [int] NULL,
	[ToMonth] [int] NULL,
	[Percentage] [decimal](5, 2) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LoanPrepaymentPenaltyTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RowNumber] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPrepaymentPenaltyTemplateDetails]  WITH CHECK ADD  CONSTRAINT [ELoanPrepaymentPenaltyTemplate_LoanPrepaymentPenaltyTemplateDetails] FOREIGN KEY([LoanPrepaymentPenaltyTemplateId])
REFERENCES [dbo].[LoanPrepaymentPenaltyTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPrepaymentPenaltyTemplateDetails] CHECK CONSTRAINT [ELoanPrepaymentPenaltyTemplate_LoanPrepaymentPenaltyTemplateDetails]
GO
