SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AMLChoiceConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Point] [decimal](16, 2) NULL,
	[IsActive] [bit] NULL,
	[AMLMasterConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AMLChoiceConfigs]  WITH CHECK ADD  CONSTRAINT [EAMLChoiceConfig_AMLMasterConfig] FOREIGN KEY([AMLMasterConfigId])
REFERENCES [dbo].[AMLMasterConfigs] ([Id])
GO
ALTER TABLE [dbo].[AMLChoiceConfigs] CHECK CONSTRAINT [EAMLChoiceConfig_AMLMasterConfig]
GO
