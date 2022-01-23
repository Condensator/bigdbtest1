SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeSocialSecurities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Year] [int] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Months] [int] NULL,
	[TypeOfInsured] [int] NULL,
	[Workdays] [int] NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NULL,
	[DNANoiReportId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmployeeSocialSecurities]  WITH CHECK ADD  CONSTRAINT [EDNANoiReport_EmployeeSocialSecurities] FOREIGN KEY([DNANoiReportId])
REFERENCES [dbo].[DNANoiReports] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EmployeeSocialSecurities] CHECK CONSTRAINT [EDNANoiReport_EmployeeSocialSecurities]
GO
