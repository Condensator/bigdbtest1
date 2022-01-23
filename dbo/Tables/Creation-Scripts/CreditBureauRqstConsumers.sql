SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauRqstConsumers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ConsenttoPullCredit] [bit] NOT NULL,
	[UseInTotalScore] [bit] NOT NULL,
	[ConsumerBureauScore] [int] NULL,
	[ConsumerBureauReport_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ConsumerBureauReport_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[ConsumerBureauReport_Content] [varbinary](82) NULL,
	[HomeAddress] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[RequestedFirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedLastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedAddress] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[RequestedCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedState] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RequestedZip] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MiddleInitial] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MaternalSurname] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NameSuffix] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Address] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[State] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Zip] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AbnormalReportIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AliasIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankruptcyOnFileIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ConsumerStatementIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ContactSubscriberIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DisputedAccountIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FileVariationIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LostOrStolenCardIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SecurityFrozenFileIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SecurityReportIndicator] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LowestRating] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MaxDelqEver] [int] NULL,
	[MosSncMostRcnt30pDelq] [int] NULL,
	[MosSncMostRcnt60pDelq] [int] NULL,
	[MosSncMostRcntDtOpnd] [int] NULL,
	[MosSncMostRcntFinTLOpnd] [int] NULL,
	[MosSncMostRcntInq] [int] NULL,
	[MosSncOldestDtOpnd] [int] NULL,
	[NetFrctMtg] [int] NULL,
	[NumBankNatlRevTL90PctRptd0To2Mos] [int] NULL,
	[NumBankNatlRevTLWBal75PctAmt] [int] NULL,
	[NumDaysInq0to11MosExclLast30Days] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NumFinTL] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NumInq0to5MosExclLast7Days] [int] NULL,
	[NumRevOpenTLWBal] [int] NULL,
	[NumRevTL30pDaysEver] [int] NULL,
	[NumRevTLWBal50PctAmt] [int] NULL,
	[NumTL] [int] NULL,
	[NumTL30pDaysEverDerogPR] [int] NULL,
	[NumTL60pDaysEverDerogPR] [int] NULL,
	[NumTL90pDaysEverDerogPR] [int] NULL,
	[NumTLOpnd3MosAndNotGT2x30Days] [int] NULL,
	[PctTLNeverDelq] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CBScore] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TotalScore] [decimal](5, 2) NULL,
	[NumPR] [int] NULL,
	[NumCollection] [int] NULL,
	[FraudIndicator] [bit] NOT NULL,
	[NumInq0to11MosExclLast30Days] [int] NULL,
	[NetFrctRev] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LowestRatingIL] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TUXmlParsedData] [varbinary](max) NULL,
	[EFUXmlParsedData] [varbinary](max) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditProfileThirdPartyRelationshipId] [bigint] NULL,
	[CreditBureauRequestId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[FullReport] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ConsumerCreditBureauId] [bigint] NOT NULL,
	[AlternateCreditBureauId] [bigint] NOT NULL,
	[ActualCreditBureauId] [bigint] NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[PartyId] [bigint] NULL,
	[ConsentDate] [date] NULL,
	[RequestedSSN_CT] [varbinary](64) NULL,
	[SSN_CT] [varbinary](64) NULL,
	[LastFourDigitRequestedSSN] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRequest_CreditBureauRqstConsumers] FOREIGN KEY([CreditBureauRequestId])
REFERENCES [dbo].[CreditBureauRequests] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers] CHECK CONSTRAINT [ECreditBureauRequest_CreditBureauRqstConsumers]
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRqstConsumer_ActualCreditBureau] FOREIGN KEY([ActualCreditBureauId])
REFERENCES [dbo].[CreditBureauConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers] CHECK CONSTRAINT [ECreditBureauRqstConsumer_ActualCreditBureau]
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRqstConsumer_AlternateCreditBureau] FOREIGN KEY([AlternateCreditBureauId])
REFERENCES [dbo].[CreditBureauConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers] CHECK CONSTRAINT [ECreditBureauRqstConsumer_AlternateCreditBureau]
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRqstConsumer_ConsumerCreditBureau] FOREIGN KEY([ConsumerCreditBureauId])
REFERENCES [dbo].[CreditBureauConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers] CHECK CONSTRAINT [ECreditBureauRqstConsumer_ConsumerCreditBureau]
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRqstConsumer_CreditProfileThirdPartyRelationship] FOREIGN KEY([CreditProfileThirdPartyRelationshipId])
REFERENCES [dbo].[CreditProfileThirdPartyRelationships] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers] CHECK CONSTRAINT [ECreditBureauRqstConsumer_CreditProfileThirdPartyRelationship]
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers]  WITH CHECK ADD  CONSTRAINT [ECreditBureauRqstConsumer_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauRqstConsumers] CHECK CONSTRAINT [ECreditBureauRqstConsumer_Party]
GO
