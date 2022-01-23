SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLAccounts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLAccountTypeId] [bigint] NOT NULL,
	[GLUserBookId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLAccounts]  WITH CHECK ADD  CONSTRAINT [EGLAccount_GLAccountType] FOREIGN KEY([GLAccountTypeId])
REFERENCES [dbo].[GLAccountTypes] ([Id])
GO
ALTER TABLE [dbo].[GLAccounts] CHECK CONSTRAINT [EGLAccount_GLAccountType]
GO
ALTER TABLE [dbo].[GLAccounts]  WITH CHECK ADD  CONSTRAINT [EGLAccount_GLUserBook] FOREIGN KEY([GLUserBookId])
REFERENCES [dbo].[GLUserBooks] ([Id])
GO
ALTER TABLE [dbo].[GLAccounts] CHECK CONSTRAINT [EGLAccount_GLUserBook]
GO
