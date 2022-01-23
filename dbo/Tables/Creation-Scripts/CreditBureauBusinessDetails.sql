SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauBusinessDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BureauCustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BureauCustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ManualCustomerSelection] [bit] NOT NULL,
	[CreditReportRequestJson] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreditReportResponseJson] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreditRatingRequestJson] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreditRatingResponseJson] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[RequestedDate] [datetimeoffset](7) NULL,
	[RequestedBy] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Source] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DataRequestStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[DataReceivedDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[ReviewStatus] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[ReportFormat] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccountBalance60PlusDbtPercent] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AccountBalance90PlusDbtPercent] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AccountBalanceCurrentPercent] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankruptciesCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankruptciesIndicatorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BusinessAddress] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[BusinessBureauScore] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BusinessCity] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[BusinessCollectionsCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BusinessReportTimeAsCurrentOwner] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BusinessLegalName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[BusinessState] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[BusinessZip] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CompositePaydexCurrent12MonthAverageAmount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CurrentManagementControlYear] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DerogatoryUccFilingsCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ExperiencesCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FileEstablishedDate] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HistoryIndicatorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IndustryNormPaydexScore] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[JudgementsCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[JudgmentsIndicatorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LiensIndicatorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NetWorthAmount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[OutOfBusinessIndicatorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PaydexFirmScore] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SatisfactoryPaymentExperiencesCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SicCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SlowAndNegativePaymentExperiencesCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[StandardPercentile] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SuitsIndicatorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TaxLiensCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TotalDelinquentAmount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TotalEmployeesCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TrendIndicatorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[YearsInBusinessCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreditReport_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreditReport_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[CreditReport_Content] [varbinary](82) NULL,
	[IsCorporate] [bit] NOT NULL,
	[RequestedCompanyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[RequestedFirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedLastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedAddress] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[RequestedCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedCountryISOAlpha2] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedState] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedZip] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[RequestedTaxId_CT] [varbinary](48) NULL,
	[PartyId] [bigint] NOT NULL,
	[CreditBureauDirectConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ReportType] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[RequestSourceId] [bigint] NULL,
	[PercentSatisfactoryExperiences] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PercentSlowNegativeExperiences] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MessageCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MessageText] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BusinessStartDate] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HighCredit] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CompositePaydexPrior12MonthAverageAmount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SlowPaymentExperiencesCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FinancialStabilityRiskStandardPercentile] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ContinuouslyReportedTradeLinesCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DaysContinuouslyReportedTradeLinesDbtCount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TradePaymentExperienceAccountsBalance] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AdditionalPaymentExperienceAccountsBalance] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TotalJudgmentsBalanceAmount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TotalTaxLiensBalanceAmount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FinancialStabilityRiskScore] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauBusinessDetails]  WITH CHECK ADD  CONSTRAINT [ECreditBureauBusinessDetail_CreditBureauDirectConfig] FOREIGN KEY([CreditBureauDirectConfigId])
REFERENCES [dbo].[CreditBureauDirectConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauBusinessDetails] CHECK CONSTRAINT [ECreditBureauBusinessDetail_CreditBureauDirectConfig]
GO
ALTER TABLE [dbo].[CreditBureauBusinessDetails]  WITH CHECK ADD  CONSTRAINT [ECreditBureauBusinessDetail_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauBusinessDetails] CHECK CONSTRAINT [ECreditBureauBusinessDetail_Party]
GO
ALTER TABLE [dbo].[CreditBureauBusinessDetails]  WITH CHECK ADD  CONSTRAINT [ECreditBureauBusinessDetail_RequestSource] FOREIGN KEY([RequestSourceId])
REFERENCES [dbo].[CreditProfiles] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauBusinessDetails] CHECK CONSTRAINT [ECreditBureauBusinessDetail_RequestSource]
GO
