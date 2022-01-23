SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DNANoiReports](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EmployerName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EmployerEIK] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreditDecisionForCreditApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DNANoiReports]  WITH CHECK ADD  CONSTRAINT [ECreditDecisionForCreditApplication_DNANoiReports] FOREIGN KEY([CreditDecisionForCreditApplicationId])
REFERENCES [dbo].[CreditDecisionForCreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DNANoiReports] CHECK CONSTRAINT [ECreditDecisionForCreditApplication_DNANoiReports]
GO
