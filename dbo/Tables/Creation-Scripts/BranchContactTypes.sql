SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BranchContactTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ContactType] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BranchContactId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BranchContactTypes]  WITH CHECK ADD  CONSTRAINT [EBranchContact_BranchContactTypes] FOREIGN KEY([BranchContactId])
REFERENCES [dbo].[BranchContacts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[BranchContactTypes] CHECK CONSTRAINT [EBranchContact_BranchContactTypes]
GO
ALTER TABLE [dbo].[BranchContactTypes]  WITH CHECK ADD  CONSTRAINT [EBranchContactType_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[BranchContactTypes] CHECK CONSTRAINT [EBranchContactType_Portfolio]
GO
