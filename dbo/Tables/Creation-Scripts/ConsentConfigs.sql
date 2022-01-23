SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConsentConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsMandatory] [bit] NOT NULL,
	[LegalDescription] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[CountryId] [bigint] NOT NULL,
	[ConsentId] [bigint] NOT NULL,
	[DocumentTypeId] [bigint] NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ConsentConfigs]  WITH CHECK ADD  CONSTRAINT [EConsentConfig_Consent] FOREIGN KEY([ConsentId])
REFERENCES [dbo].[Consents] ([Id])
GO
ALTER TABLE [dbo].[ConsentConfigs] CHECK CONSTRAINT [EConsentConfig_Consent]
GO
ALTER TABLE [dbo].[ConsentConfigs]  WITH CHECK ADD  CONSTRAINT [EConsentConfig_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[ConsentConfigs] CHECK CONSTRAINT [EConsentConfig_Country]
GO
ALTER TABLE [dbo].[ConsentConfigs]  WITH CHECK ADD  CONSTRAINT [EConsentConfig_DocumentType] FOREIGN KEY([DocumentTypeId])
REFERENCES [dbo].[DocumentTypes] ([Id])
GO
ALTER TABLE [dbo].[ConsentConfigs] CHECK CONSTRAINT [EConsentConfig_DocumentType]
GO
