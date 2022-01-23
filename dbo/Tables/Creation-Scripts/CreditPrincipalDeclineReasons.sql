SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditPrincipalDeclineReasons](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditProfileThirdPartyRelationshipId] [bigint] NOT NULL,
	[CreditDecisionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditPrincipalDeclineReasons]  WITH CHECK ADD  CONSTRAINT [ECreditDecision_CreditPrincipalDeclineReasons] FOREIGN KEY([CreditDecisionId])
REFERENCES [dbo].[CreditDecisions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditPrincipalDeclineReasons] CHECK CONSTRAINT [ECreditDecision_CreditPrincipalDeclineReasons]
GO
ALTER TABLE [dbo].[CreditPrincipalDeclineReasons]  WITH CHECK ADD  CONSTRAINT [ECreditPrincipalDeclineReason_CreditProfileThirdPartyRelationship] FOREIGN KEY([CreditProfileThirdPartyRelationshipId])
REFERENCES [dbo].[CreditProfileThirdPartyRelationships] ([Id])
GO
ALTER TABLE [dbo].[CreditPrincipalDeclineReasons] CHECK CONSTRAINT [ECreditPrincipalDeclineReason_CreditProfileThirdPartyRelationship]
GO
