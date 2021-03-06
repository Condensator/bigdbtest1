CREATE TYPE [dbo].[LienFiling] AS TABLE(
	[FilingAlias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
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
	[CustomerId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[FirstDebtorId] [bigint] NOT NULL,
	[StateId] [bigint] NOT NULL,
	[CountyId] [bigint] NULL,
	[SecuredFunderId] [bigint] NULL,
	[SecuredLegalEntityId] [bigint] NULL,
	[OriginalFilingRecordId] [bigint] NULL,
	[AuthorizingCustomerId] [bigint] NULL,
	[AuthorizingFunderId] [bigint] NULL,
	[AuthorizingLegalEntityId] [bigint] NULL,
	[ContinuationRecordId] [bigint] NULL,
	[LienCollateralTemplateId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
