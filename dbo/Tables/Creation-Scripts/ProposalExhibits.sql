SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProposalExhibits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Term] [decimal](10, 6) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsProgressFunding] [bit] NOT NULL,
	[IsIndexBasedProgressFunding] [bit] NOT NULL,
	[ProgressFundingIndexAsofDate] [date] NULL,
	[ProgressFundingBaseRate] [decimal](10, 6) NULL,
	[ProgressFundingSpread] [decimal](10, 6) NULL,
	[ProgressFundingFloorRate] [decimal](10, 6) NULL,
	[ProgressFundingCeilingRate] [decimal](10, 6) NULL,
	[ProgressFundingTotalRate] [decimal](10, 6) NULL,
	[ProgressFundingDescription] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[IsIndexBased] [bit] NOT NULL,
	[IndexAsofDate] [date] NULL,
	[BaseRate] [decimal](10, 6) NOT NULL,
	[Spread] [decimal](10, 6) NOT NULL,
	[TotalRate] [decimal](10, 6) NOT NULL,
	[IsAdvance] [bit] NOT NULL,
	[PaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[NumberofPayments] [int] NOT NULL,
	[ExpectedCommencementDate] [date] NULL,
	[VendorSubsidy_Amount] [decimal](16, 2) NOT NULL,
	[VendorSubsidy_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EstimatedBalloonAmount_Amount] [decimal](16, 2) NOT NULL,
	[EstimatedBalloonAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Revolving] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[IrregularFrequencyDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsSaleLeaseback] [bit] NOT NULL,
	[BankIndexDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DealProductTypeId] [bigint] NULL,
	[PricingBaseIndexId] [bigint] NULL,
	[ProgressFundingBaseIndexId] [bigint] NULL,
	[ProposalExhibitTemplateId] [bigint] NULL,
	[ProposalId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerTerm] [int] NULL,
	[IsRegularPaymentStream] [bit] NOT NULL,
	[DealTypeId] [bigint] NULL,
	[ProgramIndicatorConfigId] [bigint] NULL,
	[CompoundingFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[NumberOfInceptionPayments] [int] NOT NULL,
	[RentFactor] [decimal](18, 8) NOT NULL,
	[Rent_Amount] [decimal](16, 2) NOT NULL,
	[Rent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ProposedResidualFactor] [decimal](18, 8) NOT NULL,
	[GuaranteedResidualFactor] [decimal](18, 8) NOT NULL,
	[InceptionPayment_Amount] [decimal](16, 2) NOT NULL,
	[InceptionPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InceptionRentFactor] [decimal](18, 8) NOT NULL,
	[FrequencyStartDate] [date] NULL,
	[DayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDay] [int] NOT NULL,
	[ResidualatRisk_Amount] [decimal](16, 2) NOT NULL,
	[ResidualatRisk_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsResidualSharing] [bit] NOT NULL,
	[DownPayment_Amount] [decimal](16, 2) NOT NULL,
	[DownPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PricingOption] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[ProposedResidual_Amount] [decimal](16, 2) NOT NULL,
	[ProposedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GuaranteedResidual_Amount] [decimal](16, 2) NOT NULL,
	[GuaranteedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PricingCommencementDate] [date] NULL,
	[CreditProfileId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProposalExhibits]  WITH CHECK ADD  CONSTRAINT [EProposal_ProposalExhibits] FOREIGN KEY([ProposalId])
REFERENCES [dbo].[Proposals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProposalExhibits] CHECK CONSTRAINT [EProposal_ProposalExhibits]
GO
ALTER TABLE [dbo].[ProposalExhibits]  WITH CHECK ADD  CONSTRAINT [EProposalExhibit_CreditProfile] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
GO
ALTER TABLE [dbo].[ProposalExhibits] CHECK CONSTRAINT [EProposalExhibit_CreditProfile]
GO
ALTER TABLE [dbo].[ProposalExhibits]  WITH CHECK ADD  CONSTRAINT [EProposalExhibit_DealProductType] FOREIGN KEY([DealProductTypeId])
REFERENCES [dbo].[DealProductTypes] ([Id])
GO
ALTER TABLE [dbo].[ProposalExhibits] CHECK CONSTRAINT [EProposalExhibit_DealProductType]
GO
ALTER TABLE [dbo].[ProposalExhibits]  WITH CHECK ADD  CONSTRAINT [EProposalExhibit_DealType] FOREIGN KEY([DealTypeId])
REFERENCES [dbo].[DealTypes] ([Id])
GO
ALTER TABLE [dbo].[ProposalExhibits] CHECK CONSTRAINT [EProposalExhibit_DealType]
GO
ALTER TABLE [dbo].[ProposalExhibits]  WITH CHECK ADD  CONSTRAINT [EProposalExhibit_PricingBaseIndex] FOREIGN KEY([PricingBaseIndexId])
REFERENCES [dbo].[FloatRateIndexes] ([Id])
GO
ALTER TABLE [dbo].[ProposalExhibits] CHECK CONSTRAINT [EProposalExhibit_PricingBaseIndex]
GO
ALTER TABLE [dbo].[ProposalExhibits]  WITH CHECK ADD  CONSTRAINT [EProposalExhibit_ProgramIndicatorConfig] FOREIGN KEY([ProgramIndicatorConfigId])
REFERENCES [dbo].[ProgramIndicatorConfigs] ([Id])
GO
ALTER TABLE [dbo].[ProposalExhibits] CHECK CONSTRAINT [EProposalExhibit_ProgramIndicatorConfig]
GO
ALTER TABLE [dbo].[ProposalExhibits]  WITH CHECK ADD  CONSTRAINT [EProposalExhibit_ProgressFundingBaseIndex] FOREIGN KEY([ProgressFundingBaseIndexId])
REFERENCES [dbo].[FloatRateIndexes] ([Id])
GO
ALTER TABLE [dbo].[ProposalExhibits] CHECK CONSTRAINT [EProposalExhibit_ProgressFundingBaseIndex]
GO
ALTER TABLE [dbo].[ProposalExhibits]  WITH CHECK ADD  CONSTRAINT [EProposalExhibit_ProposalExhibitTemplate] FOREIGN KEY([ProposalExhibitTemplateId])
REFERENCES [dbo].[DocumentTemplates] ([Id])
GO
ALTER TABLE [dbo].[ProposalExhibits] CHECK CONSTRAINT [EProposalExhibit_ProposalExhibitTemplate]
GO
