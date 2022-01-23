SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalEntityTaxRegistrationDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[CountryId] [bigint] NOT NULL,
	[StateId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxRegistrationName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxRegistrationId] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveDate] [date] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalEntityTaxRegistrationDetails]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_LegalEntityTaxRegistrationDetails] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalEntityTaxRegistrationDetails] CHECK CONSTRAINT [ELegalEntity_LegalEntityTaxRegistrationDetails]
GO
ALTER TABLE [dbo].[LegalEntityTaxRegistrationDetails]  WITH CHECK ADD  CONSTRAINT [ELegalEntityTaxRegistrationDetail_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[LegalEntityTaxRegistrationDetails] CHECK CONSTRAINT [ELegalEntityTaxRegistrationDetail_Country]
GO
ALTER TABLE [dbo].[LegalEntityTaxRegistrationDetails]  WITH CHECK ADD  CONSTRAINT [ELegalEntityTaxRegistrationDetail_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[LegalEntityTaxRegistrationDetails] CHECK CONSTRAINT [ELegalEntityTaxRegistrationDetail_State]
GO
