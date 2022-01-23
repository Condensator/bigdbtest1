SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BankBranches](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ACHRoutingNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[BankName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[BankCode] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsPAP] [bit] NOT NULL,
	[ElectronicNetworkSupportedForFinancialTransactions] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BusinessCalendarId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsFromCustomerPortal] [bit] NOT NULL,
	[ABARoutingNumber_CT] [varbinary](48) NULL,
	[SWIFTCode_CT] [varbinary](48) NULL,
	[TransitCode_CT] [varbinary](48) NULL,
	[InternalBankNumber_CT] [varbinary](48) NULL,
	[ShouldValidateTransitCodeLength] [bit] NOT NULL,
	[GenerateControlFile] [bit] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[RecurringACHPAPLeadDays] [int] NULL,
	[OneTimeACHLeadDays] [int] NULL,
	[GenerateBalancedACH] [bit] NOT NULL,
	[CountryId] [bigint] NULL,
	[NACHAFilePaddingOption] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BankBranches]  WITH CHECK ADD  CONSTRAINT [EBankBranch_BusinessCalendar] FOREIGN KEY([BusinessCalendarId])
REFERENCES [dbo].[BusinessCalendars] ([Id])
GO
ALTER TABLE [dbo].[BankBranches] CHECK CONSTRAINT [EBankBranch_BusinessCalendar]
GO
ALTER TABLE [dbo].[BankBranches]  WITH CHECK ADD  CONSTRAINT [EBankBranch_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[BankBranches] CHECK CONSTRAINT [EBankBranch_Country]
GO
ALTER TABLE [dbo].[BankBranches]  WITH CHECK ADD  CONSTRAINT [EBankBranch_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[BankBranches] CHECK CONSTRAINT [EBankBranch_Portfolio]
GO
