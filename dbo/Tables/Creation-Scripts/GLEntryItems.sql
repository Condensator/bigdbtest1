SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLEntryItems](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[GLSystemDefinedBook] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsDebit] [bit] NOT NULL,
	[TypicalAccount] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[SortOrder] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLTransactionTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLEntryItems]  WITH CHECK ADD  CONSTRAINT [EGLTransactionType_GLEntryItems] FOREIGN KEY([GLTransactionTypeId])
REFERENCES [dbo].[GLTransactionTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GLEntryItems] CHECK CONSTRAINT [EGLTransactionType_GLEntryItems]
GO
