SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CASCOConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[VehicleAgeFrom] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[VehicleAgeTo] [int] NOT NULL,
	[InternalDealer] [decimal](5, 2) NOT NULL,
	[ExternalDealer] [decimal](5, 2) NOT NULL,
	[IsActive] [bit] NULL,
	[InsuranceCompanyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CASCOConfigs]  WITH CHECK ADD  CONSTRAINT [ECASCOConfig_InsuranceCompany] FOREIGN KEY([InsuranceCompanyId])
REFERENCES [dbo].[InsuranceCompanies] ([Id])
GO
ALTER TABLE [dbo].[CASCOConfigs] CHECK CONSTRAINT [ECASCOConfig_InsuranceCompany]
GO
