SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FinancialStatementDocuments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LatestStatementDate] [date] NOT NULL,
	[UploadStatus] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalAssets_Amount] [decimal](16, 2) NULL,
	[TotalAssets_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalLiabilities_Amount] [decimal](16, 2) NULL,
	[TotalLiabilities_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CurrentAssets_Amount] [decimal](16, 2) NULL,
	[CurrentAssets_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CurrentLiabilities_Amount] [decimal](16, 2) NULL,
	[CurrentLiabilities_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TNW_Amount] [decimal](16, 2) NULL,
	[TNW_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[EBITDA_Amount] [decimal](16, 2) NULL,
	[EBITDA_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CPLTD_Amount] [decimal](16, 2) NULL,
	[CPLTD_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestExpense_Amount] [decimal](16, 2) NULL,
	[InterestExpense_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NetIncome_Amount] [decimal](16, 2) NULL,
	[NetIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DebtToTNW] [decimal](16, 2) NULL,
	[ExceptionComment] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentRequirementId] [bigint] NULL,
	[StatusId] [bigint] NULL,
	[FinancialStatementId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[FinancialStatementDocuments]  WITH CHECK ADD  CONSTRAINT [EFinancialStatement_FinancialStatementDocuments] FOREIGN KEY([FinancialStatementId])
REFERENCES [dbo].[FinancialStatements] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FinancialStatementDocuments] CHECK CONSTRAINT [EFinancialStatement_FinancialStatementDocuments]
GO
ALTER TABLE [dbo].[FinancialStatementDocuments]  WITH CHECK ADD  CONSTRAINT [EFinancialStatementDocument_DocumentRequirement] FOREIGN KEY([DocumentRequirementId])
REFERENCES [dbo].[DocumentLists] ([Id])
GO
ALTER TABLE [dbo].[FinancialStatementDocuments] CHECK CONSTRAINT [EFinancialStatementDocument_DocumentRequirement]
GO
ALTER TABLE [dbo].[FinancialStatementDocuments]  WITH CHECK ADD  CONSTRAINT [EFinancialStatementDocument_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[DocumentStatusConfigs] ([Id])
GO
ALTER TABLE [dbo].[FinancialStatementDocuments] CHECK CONSTRAINT [EFinancialStatementDocument_Status]
GO
