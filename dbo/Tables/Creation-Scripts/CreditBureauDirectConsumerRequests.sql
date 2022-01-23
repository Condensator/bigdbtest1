SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauDirectConsumerRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsValid] [bit] NOT NULL,
	[CreditBureauConsumerDetailId] [bigint] NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauDirectConsumerRequests]  WITH CHECK ADD  CONSTRAINT [ECreditBureauDirectConsumerRequest_CreditBureauConsumerDetail] FOREIGN KEY([CreditBureauConsumerDetailId])
REFERENCES [dbo].[CreditBureauConsumerDetails] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauDirectConsumerRequests] CHECK CONSTRAINT [ECreditBureauDirectConsumerRequest_CreditBureauConsumerDetail]
GO
ALTER TABLE [dbo].[CreditBureauDirectConsumerRequests]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditBureauDirectConsumerRequests] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureauDirectConsumerRequests] CHECK CONSTRAINT [ECreditProfile_CreditBureauDirectConsumerRequests]
GO
