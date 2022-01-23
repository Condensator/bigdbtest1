CREATE TYPE [dbo].[EmployeeJobPositionHistory] AS TABLE(
	[StartDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EndDate] [date] NULL,
	[Salary_Amount] [decimal](16, 2) NULL,
	[Salary_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[JobPosition] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NULL,
	[DNANoiReportId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
