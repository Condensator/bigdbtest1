SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayOffTemplateLOBs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DiscountRate] [decimal](8, 4) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[PayOffTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayOffTemplateLOBs]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplate_PayOffTemplateLOBs] FOREIGN KEY([PayOffTemplateId])
REFERENCES [dbo].[PayOffTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayOffTemplateLOBs] CHECK CONSTRAINT [EPayOffTemplate_PayOffTemplateLOBs]
GO
ALTER TABLE [dbo].[PayOffTemplateLOBs]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplateLOB_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplateLOBs] CHECK CONSTRAINT [EPayOffTemplateLOB_LineofBusiness]
GO
