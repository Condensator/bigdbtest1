SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MasterAgreements](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[AgreementAlias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AgreementDate] [date] NULL,
	[ReceivedDate] [date] NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LineofBusinessId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AgreementTypeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[MasterAgreements]  WITH CHECK ADD  CONSTRAINT [EMasterAgreement_AgreementType] FOREIGN KEY([AgreementTypeId])
REFERENCES [dbo].[AgreementTypes] ([Id])
GO
ALTER TABLE [dbo].[MasterAgreements] CHECK CONSTRAINT [EMasterAgreement_AgreementType]
GO
ALTER TABLE [dbo].[MasterAgreements]  WITH CHECK ADD  CONSTRAINT [EMasterAgreement_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[MasterAgreements] CHECK CONSTRAINT [EMasterAgreement_Customer]
GO
ALTER TABLE [dbo].[MasterAgreements]  WITH CHECK ADD  CONSTRAINT [EMasterAgreement_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[MasterAgreements] CHECK CONSTRAINT [EMasterAgreement_LegalEntity]
GO
ALTER TABLE [dbo].[MasterAgreements]  WITH CHECK ADD  CONSTRAINT [EMasterAgreement_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[MasterAgreements] CHECK CONSTRAINT [EMasterAgreement_LineofBusiness]
GO
