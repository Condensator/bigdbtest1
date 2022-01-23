SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanYields](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Yield] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreTaxWithoutFees] [decimal](10, 6) NOT NULL,
	[PreTaxWithFees] [decimal](10, 6) NOT NULL,
	[PostTaxWithoutFees] [decimal](10, 6) NOT NULL,
	[PostTaxWithFees] [decimal](10, 6) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanYields]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanYields] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanYields] CHECK CONSTRAINT [ELoanFinance_LoanYields]
GO
