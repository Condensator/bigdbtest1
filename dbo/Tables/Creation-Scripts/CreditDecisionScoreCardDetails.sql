SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditDecisionScoreCardDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RuleName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Conditions] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Result] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreditDecisionScoreCardId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditDecisionScoreCardDetails]  WITH CHECK ADD  CONSTRAINT [ECreditDecisionScoreCard_CreditDecisionScoreCardDetails] FOREIGN KEY([CreditDecisionScoreCardId])
REFERENCES [dbo].[CreditDecisionScoreCards] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditDecisionScoreCardDetails] CHECK CONSTRAINT [ECreditDecisionScoreCard_CreditDecisionScoreCardDetails]
GO
