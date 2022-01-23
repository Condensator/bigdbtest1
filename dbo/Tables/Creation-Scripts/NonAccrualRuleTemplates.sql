SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NonAccrualRuleTemplates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[DaysPastDue] [int] NOT NULL,
	[Basis] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[MinimumPercentageofBasis] [decimal](5, 2) NULL,
	[MinimumQualifyingAmount_Amount] [decimal](16, 2) NOT NULL,
	[MinimumQualifyingAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[NonAccrualDateOption] [nvarchar](26) COLLATE Latin1_General_CI_AS NOT NULL,
	[DoubtfulCollectability] [bit] NOT NULL,
	[BillingSuppressed] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[NonAccrualRuleTemplates]  WITH CHECK ADD  CONSTRAINT [ENonAccrualRuleTemplate_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[NonAccrualRuleTemplates] CHECK CONSTRAINT [ENonAccrualRuleTemplate_Portfolio]
GO
