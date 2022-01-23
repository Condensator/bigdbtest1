SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditProfileSyndicationFundingSources](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ParticipationPercentage] [decimal](18, 8) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FunderId] [bigint] NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditProfileSyndicationFundingSources]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditProfileSyndicationFundingSources] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditProfileSyndicationFundingSources] CHECK CONSTRAINT [ECreditProfile_CreditProfileSyndicationFundingSources]
GO
ALTER TABLE [dbo].[CreditProfileSyndicationFundingSources]  WITH CHECK ADD  CONSTRAINT [ECreditProfileSyndicationFundingSource_Funder] FOREIGN KEY([FunderId])
REFERENCES [dbo].[Funders] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileSyndicationFundingSources] CHECK CONSTRAINT [ECreditProfileSyndicationFundingSource_Funder]
GO
