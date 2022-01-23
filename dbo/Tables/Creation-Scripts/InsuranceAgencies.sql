SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InsuranceAgencies](
	[Id] [bigint] NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[PhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[FaxNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ActivationDate] [date] NULL,
	[InactivationDate] [date] NULL,
	[InactivationReason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InsuranceAgencies]  WITH CHECK ADD  CONSTRAINT [EInsuranceAgency_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[InsuranceAgencies] CHECK CONSTRAINT [EInsuranceAgency_Portfolio]
GO
ALTER TABLE [dbo].[InsuranceAgencies]  WITH CHECK ADD  CONSTRAINT [EParty_InsuranceAgency] FOREIGN KEY([Id])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[InsuranceAgencies] CHECK CONSTRAINT [EParty_InsuranceAgency]
GO
