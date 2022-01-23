CREATE TYPE [dbo].[LegalRelief] AS TABLE(
	[LegalReliefType] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Active] [bit] NOT NULL,
	[LegalReliefRecordNumber] [bigint] NOT NULL,
	[FundsReceived_Amount] [decimal](16, 2) NULL,
	[FundsReceived_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FilingDate] [date] NULL,
	[POCDeadlineDate] [date] NULL,
	[ReaffirmationDate] [date] NULL,
	[ConfirmationDate] [date] NULL,
	[DischargeDate] [date] NULL,
	[DismissalDate] [date] NULL,
	[Notes] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[TrusteeAppointed] [bit] NOT NULL,
	[DebtorinPossession] [bit] NOT NULL,
	[BankruptcyNoticeNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ConversionDate] [date] NULL,
	[DebtorNotes] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[PlacedwithOutsideCounsel] [bit] NOT NULL,
	[Attorney] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TrusteeName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Address1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Address2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Zip] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[OfficePhone] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[CellPhone] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[FaxNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[EMailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[TrusteeNotes] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[BarDate] [date] NULL,
	[ReceiverName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[WebPage] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[StateCourtDistrict] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ReceiverOfficePhone] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ReceiverDirectPhone] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ReceiverEmailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Neighborhood] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[SubdivisionOrMunicipality] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CourtId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[PartyContactId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO