SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EntityEnumFields](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Entity] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Field] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[TableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EnumConfigId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EntityEnumFields]  WITH CHECK ADD  CONSTRAINT [EEntityEnumField_EnumConfig] FOREIGN KEY([EnumConfigId])
REFERENCES [dbo].[EnumConfigs] ([Id])
GO
ALTER TABLE [dbo].[EntityEnumFields] CHECK CONSTRAINT [EEntityEnumField_EnumConfig]
GO
