SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityEntityConfigs](
	[Id] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[QuerySource] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TextProperty] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[GridName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityEntityConfigs]  WITH CHECK ADD  CONSTRAINT [EEntityConfig_ActivityEntityConfig] FOREIGN KEY([Id])
REFERENCES [dbo].[EntityConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityEntityConfigs] CHECK CONSTRAINT [EEntityConfig_ActivityEntityConfig]
GO
