SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Drivers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DriverCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[DriverType] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[EmployeeID] [int] NULL,
	[LicenseNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LicenseExpiryDate] [date] NULL,
	[LicenseIssueDate] [date] NULL,
	[ClassCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AnnualInsuranceCost] [decimal](16, 2) NULL,
	[PIN] [bigint] NULL,
	[Active] [bit] NOT NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[MVRRequired] [bit] NOT NULL,
	[MVRStatus] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[MVRReviewedBy] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[MVRLastReviewedDate] [date] NULL,
	[MVRLastRunDate] [date] NULL,
	[Reason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CustomerId] [bigint] NOT NULL,
	[RelatedDriverId] [bigint] NULL,
	[LicenseStateId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ExternalDriverId] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreationDate] [date] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Drivers]  WITH CHECK ADD  CONSTRAINT [EDriver_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[Drivers] CHECK CONSTRAINT [EDriver_Customer]
GO
ALTER TABLE [dbo].[Drivers]  WITH CHECK ADD  CONSTRAINT [EDriver_LicenseState] FOREIGN KEY([LicenseStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[Drivers] CHECK CONSTRAINT [EDriver_LicenseState]
GO
ALTER TABLE [dbo].[Drivers]  WITH CHECK ADD  CONSTRAINT [EDriver_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[Drivers] CHECK CONSTRAINT [EDriver_Portfolio]
GO
ALTER TABLE [dbo].[Drivers]  WITH CHECK ADD  CONSTRAINT [EDriver_RelatedDriver] FOREIGN KEY([RelatedDriverId])
REFERENCES [dbo].[Drivers] ([Id])
GO
ALTER TABLE [dbo].[Drivers] CHECK CONSTRAINT [EDriver_RelatedDriver]
GO
