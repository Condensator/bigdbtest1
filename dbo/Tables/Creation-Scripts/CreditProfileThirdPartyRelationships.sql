SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditProfileThirdPartyRelationships](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RelationshipPercentage] [decimal](5, 2) NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ThirdPartyRelationshipId] [bigint] NOT NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditProfileThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditProfileThirdPartyRelationships] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditProfileThirdPartyRelationships] CHECK CONSTRAINT [ECreditProfile_CreditProfileThirdPartyRelationships]
GO
ALTER TABLE [dbo].[CreditProfileThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [ECreditProfileThirdPartyRelationship_ThirdPartyRelationship] FOREIGN KEY([ThirdPartyRelationshipId])
REFERENCES [dbo].[CustomerThirdPartyRelationships] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileThirdPartyRelationships] CHECK CONSTRAINT [ECreditProfileThirdPartyRelationship_ThirdPartyRelationship]
GO
