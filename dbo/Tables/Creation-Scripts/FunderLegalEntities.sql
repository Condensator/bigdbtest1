SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FunderLegalEntities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsApproved] [bit] NOT NULL,
	[IsOnHold] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[FunderId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[FunderLegalEntities]  WITH CHECK ADD  CONSTRAINT [EFunder_FunderLegalEntities] FOREIGN KEY([FunderId])
REFERENCES [dbo].[Funders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FunderLegalEntities] CHECK CONSTRAINT [EFunder_FunderLegalEntities]
GO
ALTER TABLE [dbo].[FunderLegalEntities]  WITH CHECK ADD  CONSTRAINT [EFunderLegalEntity_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[FunderLegalEntities] CHECK CONSTRAINT [EFunderLegalEntity_LegalEntity]
GO
