SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLTemplates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsReadyToUse] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLConfigurationId] [bigint] NOT NULL,
	[GLTransactionTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLTemplates]  WITH CHECK ADD  CONSTRAINT [EGLTemplate_GLConfiguration] FOREIGN KEY([GLConfigurationId])
REFERENCES [dbo].[GLConfigurations] ([Id])
GO
ALTER TABLE [dbo].[GLTemplates] CHECK CONSTRAINT [EGLTemplate_GLConfiguration]
GO
ALTER TABLE [dbo].[GLTemplates]  WITH CHECK ADD  CONSTRAINT [EGLTemplate_GLTransactionType] FOREIGN KEY([GLTransactionTypeId])
REFERENCES [dbo].[GLTransactionTypes] ([Id])
GO
ALTER TABLE [dbo].[GLTemplates] CHECK CONSTRAINT [EGLTemplate_GLTransactionType]
GO
