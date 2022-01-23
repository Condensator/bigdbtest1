SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauConsumerDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestedDate] [datetimeoffset](7) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RequestedBy] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Source] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DataRequestStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[DataReceivedDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[ReviewStatus] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[ReportFormat] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReportType] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[ConsenttoPullCredit] [bit] NOT NULL,
	[ConsentDate] [date] NULL,
	[SocialSecurityNumber_CT] [varbinary](64) NULL,
	[LastFourDigitRequestedSSN] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MiddleInitial] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Address] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[State] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Zip] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ConsumerBureauScore] [int] NULL,
	[RequestedFirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedLastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HomeAddress] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[RequestedAddress] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[RequestedCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedState] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedZip] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedSSN_CT] [varbinary](64) NULL,
	[ScorePercentile] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankruptcyChapterNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankruptcyAssetAmount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankruptcyVolutaryIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DisputedAccountIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MosSncMostRcnt30pDelq] [int] NULL,
	[MosSncMostRcnt60pDelq] [int] NULL,
	[FileVariationIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TradelineBalanceAmount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TradelineBalanceDate] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TradelinePastDueAmount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreditReport_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreditReport_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[CreditReport_Content] [varbinary](82) NULL,
	[CreditReportRequestJson] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreditReportResponseJson] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[PartyId] [bigint] NOT NULL,
	[CreditBureauDirectConfigId] [bigint] NOT NULL,
	[RequestSourceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SSN_CT] [varbinary](64) NULL,
	[CreditRatingRequestJson] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreditRatingResponseJson] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsCorporate] [bit] NOT NULL,
	[IsSoleProprietor] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauConsumerDetails]  WITH CHECK ADD  CONSTRAINT [ECreditBureauConsumerDetail_CreditBureauDirectConfig] FOREIGN KEY([CreditBureauDirectConfigId])
REFERENCES [dbo].[CreditBureauDirectConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauConsumerDetails] CHECK CONSTRAINT [ECreditBureauConsumerDetail_CreditBureauDirectConfig]
GO
ALTER TABLE [dbo].[CreditBureauConsumerDetails]  WITH CHECK ADD  CONSTRAINT [ECreditBureauConsumerDetail_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauConsumerDetails] CHECK CONSTRAINT [ECreditBureauConsumerDetail_Party]
GO
ALTER TABLE [dbo].[CreditBureauConsumerDetails]  WITH CHECK ADD  CONSTRAINT [ECreditBureauConsumerDetail_RequestSource] FOREIGN KEY([RequestSourceId])
REFERENCES [dbo].[CreditProfiles] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauConsumerDetails] CHECK CONSTRAINT [ECreditBureauConsumerDetail_RequestSource]
GO
