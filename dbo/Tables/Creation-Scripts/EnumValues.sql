SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EnumValues](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Value] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Label] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Culture] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EnumConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EnumValues]  WITH CHECK ADD  CONSTRAINT [EEnumConfig_EnumValues] FOREIGN KEY([EnumConfigId])
REFERENCES [dbo].[EnumConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EnumValues] CHECK CONSTRAINT [EEnumConfig_EnumValues]
GO
