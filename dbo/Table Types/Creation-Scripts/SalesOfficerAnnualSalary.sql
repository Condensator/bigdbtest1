CREATE TYPE [dbo].[SalesOfficerAnnualSalary] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
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
	[SalesOfficerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
