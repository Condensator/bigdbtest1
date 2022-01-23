SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeJobPositionHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[StartDate] [date] NULL,
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
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmployeeJobPositionHistories]  WITH CHECK ADD  CONSTRAINT [EDNANoiReport_EmployeeJobPositionHistories] FOREIGN KEY([DNANoiReportId])
REFERENCES [dbo].[DNANoiReports] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EmployeeJobPositionHistories] CHECK CONSTRAINT [EDNANoiReport_EmployeeJobPositionHistories]
GO
