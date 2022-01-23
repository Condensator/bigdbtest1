CREATE TYPE [dbo].[ReclassIncomeGLDetail] AS TABLE(
	[GLEntryItemName] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Amount] [decimal](16, 2) NULL
)
GO
