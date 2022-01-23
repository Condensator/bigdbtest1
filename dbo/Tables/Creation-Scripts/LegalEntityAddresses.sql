SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalEntityAddresses](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[AddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Division] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsMain] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Neighborhood] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SubdivisionOrMunicipality] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsHeadquarter] [bit] NOT NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalEntityAddresses]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_LegalEntityAddresses] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalEntityAddresses] CHECK CONSTRAINT [ELegalEntity_LegalEntityAddresses]
GO
ALTER TABLE [dbo].[LegalEntityAddresses]  WITH CHECK ADD  CONSTRAINT [ELegalEntityAddress_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[LegalEntityAddresses] CHECK CONSTRAINT [ELegalEntityAddress_State]
GO
