SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LienFilings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FilingAlias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Type] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[TransactionType] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[RecordType] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[Division] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AmendmentType] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[AmendmentAction] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[AmendmentRecordDate] [date] NULL,
	[SecuredPartyType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsAssignee] [bit] NOT NULL,
	[CollateralText] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CollateralClassification] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[InternalComment] [nvarchar](4000) COLLATE Latin1_General_CI_AS NULL,
	[PrincipalAmount_Amount] [decimal](16, 2) NULL,
	[PrincipalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsNoFixedDate] [bit] NOT NULL,
	[DateOfMaturity] [date] NULL,
	[SigningPlace] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SigningDate] [date] NULL,
	[IsAutoContinuation] [bit] NOT NULL,
	[ContinuationDate] [date] NULL,
	[AuthorizingPartyType] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[AltFilingType] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[AltNameDesignation] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[LienDebtorAltCapacity] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsManualUpdate] [bit] NOT NULL,
	[IsRenewalRecordGenerated] [bit] NOT NULL,
	[LienTransactions] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[LienRefNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SubmissionStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[IsFloridaDocumentaryStampTax] [bit] NOT NULL,
	[MaximumIndebtednessAmount_Amount] [decimal](16, 2) NULL,
	[MaximumIndebtednessAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LienFilingStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[JurisdictionId] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AttachmentId] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AttachmentURL] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[FirstDebtorId] [bigint] NOT NULL,
	[StateId] [bigint] NOT NULL,
	[SecuredFunderId] [bigint] NULL,
	[SecuredLegalEntityId] [bigint] NULL,
	[OriginalFilingRecordId] [bigint] NULL,
	[AuthorizingCustomerId] [bigint] NULL,
	[AuthorizingFunderId] [bigint] NULL,
	[AuthorizingLegalEntityId] [bigint] NULL,
	[ContinuationRecordId] [bigint] NULL,
	[LienCollateralTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CountyId] [bigint] NULL,
	[IncludeSerialNumberInAssetInformation] [bit] NOT NULL,
	[IsFinancialStatementRequiredForRealEstate] [bit] NOT NULL,
	[RecordOwnerNameAndAddress] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[FLTaxStamp] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[InDebType] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[AttachmentType] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[InitialFileDate] [date] NULL,
	[InitialFileNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HistoricalExpirationDate] [date] NULL,
	[FinancingStatementDate] [date] NULL,
	[FinancingStatementFileNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[OriginalDebtorName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[OriginalSecuredPartyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[IsUpdateFilingRequired] [bit] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_AuthorizingCustomer] FOREIGN KEY([AuthorizingCustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_AuthorizingCustomer]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_AuthorizingFunder] FOREIGN KEY([AuthorizingFunderId])
REFERENCES [dbo].[Funders] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_AuthorizingFunder]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_AuthorizingLegalEntity] FOREIGN KEY([AuthorizingLegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_AuthorizingLegalEntity]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_BusinessUnit]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_ContinuationRecord] FOREIGN KEY([ContinuationRecordId])
REFERENCES [dbo].[LienFilings] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_ContinuationRecord]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_Contract]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_County] FOREIGN KEY([CountyId])
REFERENCES [dbo].[Counties] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_County]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_Customer]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_FirstDebtor] FOREIGN KEY([FirstDebtorId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_FirstDebtor]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_LienCollateralTemplate] FOREIGN KEY([LienCollateralTemplateId])
REFERENCES [dbo].[LienCollateralTextTemplates] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_LienCollateralTemplate]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_OriginalFilingRecord] FOREIGN KEY([OriginalFilingRecordId])
REFERENCES [dbo].[LienFilings] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_OriginalFilingRecord]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_SecuredFunder] FOREIGN KEY([SecuredFunderId])
REFERENCES [dbo].[Funders] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_SecuredFunder]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_SecuredLegalEntity] FOREIGN KEY([SecuredLegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_SecuredLegalEntity]
GO
ALTER TABLE [dbo].[LienFilings]  WITH CHECK ADD  CONSTRAINT [ELienFiling_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[LienFilings] CHECK CONSTRAINT [ELienFiling_State]
GO
