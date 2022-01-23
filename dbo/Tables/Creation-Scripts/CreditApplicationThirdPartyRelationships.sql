SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditApplicationThirdPartyRelationships](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RelationshipPercentage] [decimal](5, 2) NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ThirdPartyRelationshipId] [bigint] NOT NULL,
	[CreditApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsCreatedFromCreditApplication] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditApplicationThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_CreditApplicationThirdPartyRelationships] FOREIGN KEY([CreditApplicationId])
REFERENCES [dbo].[CreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditApplicationThirdPartyRelationships] CHECK CONSTRAINT [ECreditApplication_CreditApplicationThirdPartyRelationships]
GO
ALTER TABLE [dbo].[CreditApplicationThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationThirdPartyRelationship_ThirdPartyRelationship] FOREIGN KEY([ThirdPartyRelationshipId])
REFERENCES [dbo].[CustomerThirdPartyRelationships] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationThirdPartyRelationships] CHECK CONSTRAINT [ECreditApplicationThirdPartyRelationship_ThirdPartyRelationship]
GO
