SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalesOfficerAnnualSalaries](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BaseSalary_Amount] [decimal](16, 2) NULL,
	[BaseSalary_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AnnualSalesGoals_Amount] [decimal](16, 2) NULL,
	[AnnualSalesGoals_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Year] [decimal](4, 0) NOT NULL,
	[SalaryCap_Amount] [decimal](16, 2) NULL,
	[SalaryCap_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AnnualFeeIncomeGoal_Amount] [decimal](16, 2) NULL,
	[AnnualFeeIncomeGoal_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RowNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SalesOfficerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SalesOfficerAnnualSalaries]  WITH CHECK ADD  CONSTRAINT [ESalesOfficer_SalesOfficerAnnualSalaries] FOREIGN KEY([SalesOfficerId])
REFERENCES [dbo].[SalesOfficers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SalesOfficerAnnualSalaries] CHECK CONSTRAINT [ESalesOfficer_SalesOfficerAnnualSalaries]
GO
