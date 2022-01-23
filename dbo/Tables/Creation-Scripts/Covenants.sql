SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Covenants](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Frequency] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](22) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[StatementDate] [date] NOT NULL,
	[StatusDueDate] [date] NOT NULL,
	[TargetMinimumAmount] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[TargetMaximumAmount] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ReviewDays] [int] NULL,
	[ToEmail] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CcEmail] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[RemediationPlanNarrative] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsPrimaryCustomer] [bit] NOT NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[LastStatus] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[LastStatementDate] [date] NULL,
	[LastStatusDate] [date] NULL,
	[LastReviewStatus] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[LastReviewStatementDate] [date] NULL,
	[LastReviewStatusDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[IsOverDue] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LastReviewById] [bigint] NULL,
	[ThirdPartyDealRelationshipId] [bigint] NULL,
	[CreditDecisionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Covenants]  WITH CHECK ADD  CONSTRAINT [ECovenant_LastReviewBy] FOREIGN KEY([LastReviewById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Covenants] CHECK CONSTRAINT [ECovenant_LastReviewBy]
GO
ALTER TABLE [dbo].[Covenants]  WITH CHECK ADD  CONSTRAINT [ECovenant_ThirdPartyDealRelationship] FOREIGN KEY([ThirdPartyDealRelationshipId])
REFERENCES [dbo].[CustomerThirdPartyRelationships] ([Id])
GO
ALTER TABLE [dbo].[Covenants] CHECK CONSTRAINT [ECovenant_ThirdPartyDealRelationship]
GO
ALTER TABLE [dbo].[Covenants]  WITH CHECK ADD  CONSTRAINT [ECreditDecision_Covenants] FOREIGN KEY([CreditDecisionId])
REFERENCES [dbo].[CreditDecisions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Covenants] CHECK CONSTRAINT [ECreditDecision_Covenants]
GO
