SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Courts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CourtName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ClerkOfCourtPhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[CourtType] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Region] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[PostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[ECMUserName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ECMPassword] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ECMWebPOCFilingLink] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ECMTrainingLink] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[DeactivationDate] [date] NULL,
	[ReactivationDate] [date] NULL,
	[Comments] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Neighborhood] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[SubdivisionOrMunicipality] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Courts]  WITH CHECK ADD  CONSTRAINT [ECourt_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[Courts] CHECK CONSTRAINT [ECourt_Portfolio]
GO
ALTER TABLE [dbo].[Courts]  WITH CHECK ADD  CONSTRAINT [ECourt_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[Courts] CHECK CONSTRAINT [ECourt_State]
GO
