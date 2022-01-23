SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalReliefs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LegalReliefType] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
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
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CourtId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[PartyContactId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Neighborhood] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[SubdivisionOrMunicipality] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalReliefs]  WITH CHECK ADD  CONSTRAINT [ELegalRelief_Court] FOREIGN KEY([CourtId])
REFERENCES [dbo].[Courts] ([Id])
GO
ALTER TABLE [dbo].[LegalReliefs] CHECK CONSTRAINT [ELegalRelief_Court]
GO
ALTER TABLE [dbo].[LegalReliefs]  WITH CHECK ADD  CONSTRAINT [ELegalRelief_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LegalReliefs] CHECK CONSTRAINT [ELegalRelief_Customer]
GO
ALTER TABLE [dbo].[LegalReliefs]  WITH CHECK ADD  CONSTRAINT [ELegalRelief_PartyContact] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[LegalReliefs] CHECK CONSTRAINT [ELegalRelief_PartyContact]
GO
ALTER TABLE [dbo].[LegalReliefs]  WITH CHECK ADD  CONSTRAINT [ELegalRelief_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[LegalReliefs] CHECK CONSTRAINT [ELegalRelief_State]
GO
