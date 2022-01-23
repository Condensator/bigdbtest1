SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Plates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PlateUniqueNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IssuedDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NULL,
	[AssignmentDate] [date] NULL,
	[PlateNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ResponsibleEntity] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[DoNotRenewRegistration] [bit] NOT NULL,
	[ExpiryDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[DeactivationReason] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[RegistrationAddressType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[RegistrationName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RegistantAttentionTo] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RegistrantAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[RegistrantAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[RegistrantAddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[RegistrantCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RegistrantDivision] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RegistrantPostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[RegistrantNeighborhood] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RegistrantSubdivisionOrMunicipality] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DMVAddressType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[DMVAttentionTo] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DMVAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[DMVAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[DMVAddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[DMVCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DMVDivision] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DMVPostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[DMVNeighborhood] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DMVSubdivisionOrMunicipality] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RegistrationCountryId] [bigint] NOT NULL,
	[RegistrantCountryId] [bigint] NULL,
	[DMVCountryId] [bigint] NULL,
	[RegistrationStateId] [bigint] NOT NULL,
	[RegistantStateId] [bigint] NULL,
	[DMVStateId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[PlateTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Plates]  WITH CHECK ADD  CONSTRAINT [EPlate_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[Plates] CHECK CONSTRAINT [EPlate_Asset]
GO
ALTER TABLE [dbo].[Plates]  WITH CHECK ADD  CONSTRAINT [EPlate_DMVCountry] FOREIGN KEY([DMVCountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[Plates] CHECK CONSTRAINT [EPlate_DMVCountry]
GO
ALTER TABLE [dbo].[Plates]  WITH CHECK ADD  CONSTRAINT [EPlate_DMVState] FOREIGN KEY([DMVStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[Plates] CHECK CONSTRAINT [EPlate_DMVState]
GO
ALTER TABLE [dbo].[Plates]  WITH CHECK ADD  CONSTRAINT [EPlate_PlateType] FOREIGN KEY([PlateTypeId])
REFERENCES [dbo].[PlateTypes] ([Id])
GO
ALTER TABLE [dbo].[Plates] CHECK CONSTRAINT [EPlate_PlateType]
GO
ALTER TABLE [dbo].[Plates]  WITH CHECK ADD  CONSTRAINT [EPlate_RegistantState] FOREIGN KEY([RegistantStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[Plates] CHECK CONSTRAINT [EPlate_RegistantState]
GO
ALTER TABLE [dbo].[Plates]  WITH CHECK ADD  CONSTRAINT [EPlate_RegistrantCountry] FOREIGN KEY([RegistrantCountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[Plates] CHECK CONSTRAINT [EPlate_RegistrantCountry]
GO
ALTER TABLE [dbo].[Plates]  WITH CHECK ADD  CONSTRAINT [EPlate_RegistrationCountry] FOREIGN KEY([RegistrationCountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[Plates] CHECK CONSTRAINT [EPlate_RegistrationCountry]
GO
ALTER TABLE [dbo].[Plates]  WITH CHECK ADD  CONSTRAINT [EPlate_RegistrationState] FOREIGN KEY([RegistrationStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[Plates] CHECK CONSTRAINT [EPlate_RegistrationState]
GO
