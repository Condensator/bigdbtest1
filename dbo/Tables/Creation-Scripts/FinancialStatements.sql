SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FinancialStatements](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Frequency] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[OtherStatementType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[StatementDate] [date] NOT NULL,
	[DaysToUpload] [int] NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[UploadByDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RAIDNumber] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[FinancialStatements]  WITH CHECK ADD  CONSTRAINT [EFinancialStatement_DocumentType] FOREIGN KEY([DocumentTypeId])
REFERENCES [dbo].[DocumentTypes] ([Id])
GO
ALTER TABLE [dbo].[FinancialStatements] CHECK CONSTRAINT [EFinancialStatement_DocumentType]
GO
ALTER TABLE [dbo].[FinancialStatements]  WITH CHECK ADD  CONSTRAINT [EParty_FinancialStatements] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FinancialStatements] CHECK CONSTRAINT [EParty_FinancialStatements]
GO
