SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LienAdditionalSecuredParties](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsAssignor] [bit] NOT NULL,
	[IsRemoved] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SecuredFunderId] [bigint] NULL,
	[SecuredLegalEntityId] [bigint] NULL,
	[LienFilingId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SecuredPartyType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LienAdditionalSecuredParties]  WITH CHECK ADD  CONSTRAINT [ELienAdditionalSecuredParty_SecuredFunder] FOREIGN KEY([SecuredFunderId])
REFERENCES [dbo].[Funders] ([Id])
GO
ALTER TABLE [dbo].[LienAdditionalSecuredParties] CHECK CONSTRAINT [ELienAdditionalSecuredParty_SecuredFunder]
GO
ALTER TABLE [dbo].[LienAdditionalSecuredParties]  WITH CHECK ADD  CONSTRAINT [ELienAdditionalSecuredParty_SecuredLegalEntity] FOREIGN KEY([SecuredLegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[LienAdditionalSecuredParties] CHECK CONSTRAINT [ELienAdditionalSecuredParty_SecuredLegalEntity]
GO
ALTER TABLE [dbo].[LienAdditionalSecuredParties]  WITH CHECK ADD  CONSTRAINT [ELienFiling_LienAdditionalSecuredParties] FOREIGN KEY([LienFilingId])
REFERENCES [dbo].[LienFilings] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LienAdditionalSecuredParties] CHECK CONSTRAINT [ELienFiling_LienAdditionalSecuredParties]
GO
