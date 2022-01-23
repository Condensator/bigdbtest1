SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingCapitalizedInterests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Source] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalizedDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLJournalId] [bigint] NULL,
	[DiscountingFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingCapitalizedInterests]  WITH CHECK ADD  CONSTRAINT [EDiscountingCapitalizedInterest_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[DiscountingCapitalizedInterests] CHECK CONSTRAINT [EDiscountingCapitalizedInterest_GLJournal]
GO
ALTER TABLE [dbo].[DiscountingCapitalizedInterests]  WITH CHECK ADD  CONSTRAINT [EDiscountingFinance_DiscountingCapitalizedInterests] FOREIGN KEY([DiscountingFinanceId])
REFERENCES [dbo].[DiscountingFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingCapitalizedInterests] CHECK CONSTRAINT [EDiscountingFinance_DiscountingCapitalizedInterests]
GO
