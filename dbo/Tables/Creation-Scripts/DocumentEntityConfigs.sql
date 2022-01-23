SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentEntityConfigs](
	[GenerationAllowed] [bit] NOT NULL,
	[GenerationAllowedExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[LanguageExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[QuerySource] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TextProperty] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[GridName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsBusinessEntityMandatory] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentEntityConfigs]  WITH CHECK ADD  CONSTRAINT [EEntityConfig_DocumentEntityConfig] FOREIGN KEY([Id])
REFERENCES [dbo].[EntityConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentEntityConfigs] CHECK CONSTRAINT [EEntityConfig_DocumentEntityConfig]
GO
