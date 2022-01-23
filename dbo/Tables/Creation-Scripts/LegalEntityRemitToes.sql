SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalEntityRemitToes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RemitToId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalEntityRemitToes]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_LegalEntityRemitToes] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalEntityRemitToes] CHECK CONSTRAINT [ELegalEntity_LegalEntityRemitToes]
GO
ALTER TABLE [dbo].[LegalEntityRemitToes]  WITH CHECK ADD  CONSTRAINT [ELegalEntityRemitTo_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[LegalEntityRemitToes] CHECK CONSTRAINT [ELegalEntityRemitTo_RemitTo]
GO
