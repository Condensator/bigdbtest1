SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalesOfficers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EmployeeCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[OperatingTierVolumeFloorStartDate] [date] NULL,
	[OperatingTierVolumeFloorExpirationDate] [date] NULL,
	[JobTittle] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[DealCommissionCap_Amount] [decimal](16, 2) NULL,
	[DealCommissionCap_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsCommissionable] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CurrencyId] [bigint] NOT NULL,
	[PrimaryLineOfBussinessId] [bigint] NOT NULL,
	[UserNameId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[OperatingTierVolume_Amount] [decimal](16, 2) NULL,
	[OperatingTierVolume_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SalesOfficers]  WITH CHECK ADD  CONSTRAINT [ESalesOfficer_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[SalesOfficers] CHECK CONSTRAINT [ESalesOfficer_Currency]
GO
ALTER TABLE [dbo].[SalesOfficers]  WITH CHECK ADD  CONSTRAINT [ESalesOfficer_PrimaryLineOfBussiness] FOREIGN KEY([PrimaryLineOfBussinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[SalesOfficers] CHECK CONSTRAINT [ESalesOfficer_PrimaryLineOfBussiness]
GO
ALTER TABLE [dbo].[SalesOfficers]  WITH CHECK ADD  CONSTRAINT [ESalesOfficer_UserName] FOREIGN KEY([UserNameId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[SalesOfficers] CHECK CONSTRAINT [ESalesOfficer_UserName]
GO
