SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalEntitiesForUsers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsDefault] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalEntitiesForUsers]  WITH CHECK ADD  CONSTRAINT [ELegalEntitiesForUser_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[LegalEntitiesForUsers] CHECK CONSTRAINT [ELegalEntitiesForUser_LegalEntity]
GO
ALTER TABLE [dbo].[LegalEntitiesForUsers]  WITH CHECK ADD  CONSTRAINT [EUser_LegalEntitiesForUsers] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalEntitiesForUsers] CHECK CONSTRAINT [EUser_LegalEntitiesForUsers]
GO
