SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptApplications](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PostDate] [date] NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AmountApplied_Amount] [decimal](16, 2) NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsFullCash] [bit] NOT NULL,
	[CreditApplied_Amount] [decimal](16, 2) NOT NULL,
	[CreditApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableDisplayOption] [nvarchar](24) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ReceiptHierarchyTemplateId] [bigint] NULL,
	[ApplyByReceivable] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptApplications]  WITH CHECK ADD  CONSTRAINT [EReceiptApplication_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplications] CHECK CONSTRAINT [EReceiptApplication_Receipt]
GO
ALTER TABLE [dbo].[ReceiptApplications]  WITH CHECK ADD  CONSTRAINT [EReceiptApplication_ReceiptHierarchyTemplate] FOREIGN KEY([ReceiptHierarchyTemplateId])
REFERENCES [dbo].[ReceiptHierarchyTemplates] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplications] CHECK CONSTRAINT [EReceiptApplication_ReceiptHierarchyTemplate]
GO
