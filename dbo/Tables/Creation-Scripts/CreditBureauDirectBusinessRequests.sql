SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauDirectBusinessRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditBureauBusinessDetailId] [bigint] NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsValid] [bit] NOT NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauDirectBusinessRequests]  WITH CHECK ADD  CONSTRAINT [ECreditBureauDirectBusinessRequest_CreditBureauBusinessDetail] FOREIGN KEY([CreditBureauBusinessDetailId])
REFERENCES [dbo].[CreditBureauBusinessDetails] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauDirectBusinessRequests] CHECK CONSTRAINT [ECreditBureauDirectBusinessRequest_CreditBureauBusinessDetail]
GO
ALTER TABLE [dbo].[CreditBureauDirectBusinessRequests]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditBureauDirectBusinessRequests] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureauDirectBusinessRequests] CHECK CONSTRAINT [ECreditProfile_CreditBureauDirectBusinessRequests]
GO
