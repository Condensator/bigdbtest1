SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ShellCustomerDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsCorporate] [bit] NOT NULL,
	[SFDCId] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MiddleName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CompanyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[IsSoleProprietor] [bit] NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[CIPDocumentSourceForName] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[LegalNameValidationDate] [date] NULL,
	[PartyType] [nvarchar](42) COLLATE Latin1_General_CI_AS NULL,
	[IncomeTaxStatus] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[BusinessTypeId] [bigint] NULL,
	[StateOfIncorporationId] [bigint] NULL,
	[PercentageOfGovernmentOwnership] [decimal](5, 2) NULL,
	[ApprovedExchangeId] [bigint] NULL,
	[ApprovedRegulatorId] [bigint] NULL,
	[JurisdictionOfSovereignId] [bigint] NULL,
	[BusinessTypeNAICSCodeId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DateOfBirth] [date] NULL,
	[UniqueIdentificationNumber] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[IsShellCustomerCreated] [bit] NOT NULL,
	[CIPDocumentSourceNameId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ShellCustomerDetails]  WITH CHECK ADD  CONSTRAINT [EShellCustomerDetail_ApprovedExchange] FOREIGN KEY([ApprovedExchangeId])
REFERENCES [dbo].[CustomerApprovedExchangesConfigs] ([Id])
GO
ALTER TABLE [dbo].[ShellCustomerDetails] CHECK CONSTRAINT [EShellCustomerDetail_ApprovedExchange]
GO
ALTER TABLE [dbo].[ShellCustomerDetails]  WITH CHECK ADD  CONSTRAINT [EShellCustomerDetail_ApprovedRegulator] FOREIGN KEY([ApprovedRegulatorId])
REFERENCES [dbo].[CustomerApprovedRegulatorsConfigs] ([Id])
GO
ALTER TABLE [dbo].[ShellCustomerDetails] CHECK CONSTRAINT [EShellCustomerDetail_ApprovedRegulator]
GO
ALTER TABLE [dbo].[ShellCustomerDetails]  WITH CHECK ADD  CONSTRAINT [EShellCustomerDetail_BusinessType] FOREIGN KEY([BusinessTypeId])
REFERENCES [dbo].[BusinessTypes] ([Id])
GO
ALTER TABLE [dbo].[ShellCustomerDetails] CHECK CONSTRAINT [EShellCustomerDetail_BusinessType]
GO
ALTER TABLE [dbo].[ShellCustomerDetails]  WITH CHECK ADD  CONSTRAINT [EShellCustomerDetail_BusinessTypeNAICSCode] FOREIGN KEY([BusinessTypeNAICSCodeId])
REFERENCES [dbo].[BusinessTypeNAICSCodes] ([Id])
GO
ALTER TABLE [dbo].[ShellCustomerDetails] CHECK CONSTRAINT [EShellCustomerDetail_BusinessTypeNAICSCode]
GO
ALTER TABLE [dbo].[ShellCustomerDetails]  WITH CHECK ADD  CONSTRAINT [EShellCustomerDetail_CIPDocumentSourceName] FOREIGN KEY([CIPDocumentSourceNameId])
REFERENCES [dbo].[CIPDocumentSourceConfigs] ([Id])
GO
ALTER TABLE [dbo].[ShellCustomerDetails] CHECK CONSTRAINT [EShellCustomerDetail_CIPDocumentSourceName]
GO
ALTER TABLE [dbo].[ShellCustomerDetails]  WITH CHECK ADD  CONSTRAINT [EShellCustomerDetail_JurisdictionOfSovereign] FOREIGN KEY([JurisdictionOfSovereignId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[ShellCustomerDetails] CHECK CONSTRAINT [EShellCustomerDetail_JurisdictionOfSovereign]
GO
ALTER TABLE [dbo].[ShellCustomerDetails]  WITH CHECK ADD  CONSTRAINT [EShellCustomerDetail_StateOfIncorporation] FOREIGN KEY([StateOfIncorporationId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[ShellCustomerDetails] CHECK CONSTRAINT [EShellCustomerDetail_StateOfIncorporation]
GO
