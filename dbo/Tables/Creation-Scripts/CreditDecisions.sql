SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditDecisions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DecisionName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[DecisionDate] [date] NOT NULL,
	[Intention] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[ExpiryDate] [date] NULL,
	[StatusDate] [date] NULL,
	[IsApprovedOnBehalf] [bit] NOT NULL,
	[ApprovedAmount_Amount] [decimal](16, 2) NULL,
	[ApprovedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsSingleLoanAuthorityUsed] [bit] NOT NULL,
	[IsCarveOutUsed] [bit] NOT NULL,
	[IsConditionalApproval] [bit] NOT NULL,
	[DecisionStatus] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[DecisionComments] [nvarchar](2500) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[RACOverride] [bit] NOT NULL,
	[RACOverrideReason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[LowSideOverride] [bit] NOT NULL,
	[BusinessAdditionalCollateral] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PrincipalAdditionalCollateral] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[StandardCollateral] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[SecurityDepositAmount_Amount] [decimal](16, 2) NULL,
	[SecurityDepositAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[WriteUp] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[DecisionDocumentation] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ApprovedById] [bigint] NULL,
	[ApprovedOnBehalfUserId] [bigint] NULL,
	[StatusChangedById] [bigint] NULL,
	[LGDCodeId] [bigint] NULL,
	[LowSideOverrideReasonCodeId] [bigint] NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[OtherCreditApprovalCondition] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[ApprovedTransactionAmount_Amount] [decimal](16, 2) NULL,
	[ApprovedTransactionAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[SameDayCreditApprovals_Amount] [decimal](24, 2) NULL,
	[SameDayCreditApprovals_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReplacementAmount_Amount] [decimal](24, 2) NULL,
	[ReplacementAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ToleranceAmount_Amount] [decimal](16, 2) NOT NULL,
	[ToleranceAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ToleranceFactor] [decimal](18, 8) NOT NULL,
	[IsRevolving] [bit] NOT NULL,
	[UsedAmount_Amount] [decimal](16, 2) NOT NULL,
	[UsedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsAvailableBalanceCalculated] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditDecisions]  WITH CHECK ADD  CONSTRAINT [ECreditDecision_ApprovedBy] FOREIGN KEY([ApprovedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CreditDecisions] CHECK CONSTRAINT [ECreditDecision_ApprovedBy]
GO
ALTER TABLE [dbo].[CreditDecisions]  WITH CHECK ADD  CONSTRAINT [ECreditDecision_ApprovedOnBehalfUser] FOREIGN KEY([ApprovedOnBehalfUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CreditDecisions] CHECK CONSTRAINT [ECreditDecision_ApprovedOnBehalfUser]
GO
ALTER TABLE [dbo].[CreditDecisions]  WITH CHECK ADD  CONSTRAINT [ECreditDecision_LGDCode] FOREIGN KEY([LGDCodeId])
REFERENCES [dbo].[CreditLGDCodes] ([Id])
GO
ALTER TABLE [dbo].[CreditDecisions] CHECK CONSTRAINT [ECreditDecision_LGDCode]
GO
ALTER TABLE [dbo].[CreditDecisions]  WITH CHECK ADD  CONSTRAINT [ECreditDecision_LowSideOverrideReasonCode] FOREIGN KEY([LowSideOverrideReasonCodeId])
REFERENCES [dbo].[LowSideOverrideReasonCodes] ([Id])
GO
ALTER TABLE [dbo].[CreditDecisions] CHECK CONSTRAINT [ECreditDecision_LowSideOverrideReasonCode]
GO
ALTER TABLE [dbo].[CreditDecisions]  WITH CHECK ADD  CONSTRAINT [ECreditDecision_StatusChangedBy] FOREIGN KEY([StatusChangedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CreditDecisions] CHECK CONSTRAINT [ECreditDecision_StatusChangedBy]
GO
ALTER TABLE [dbo].[CreditDecisions]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditDecisions] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditDecisions] CHECK CONSTRAINT [ECreditProfile_CreditDecisions]
GO
