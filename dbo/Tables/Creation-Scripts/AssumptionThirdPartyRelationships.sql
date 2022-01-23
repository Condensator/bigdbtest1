SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssumptionThirdPartyRelationships](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RelationshipPercentage] [decimal](5, 2) NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ThirdPartyRelationshipId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssumptionThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [EAssumption_AssumptionThirdPartyRelationships] FOREIGN KEY([AssumptionId])
REFERENCES [dbo].[Assumptions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssumptionThirdPartyRelationships] CHECK CONSTRAINT [EAssumption_AssumptionThirdPartyRelationships]
GO
ALTER TABLE [dbo].[AssumptionThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [EAssumptionThirdPartyRelationship_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[AssumptionThirdPartyRelationships] CHECK CONSTRAINT [EAssumptionThirdPartyRelationship_Customer]
GO
ALTER TABLE [dbo].[AssumptionThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [EAssumptionThirdPartyRelationship_ThirdPartyRelationship] FOREIGN KEY([ThirdPartyRelationshipId])
REFERENCES [dbo].[CustomerThirdPartyRelationships] ([Id])
GO
ALTER TABLE [dbo].[AssumptionThirdPartyRelationships] CHECK CONSTRAINT [EAssumptionThirdPartyRelationship_ThirdPartyRelationship]
GO
