SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MetaEntityExtensionFields](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DataType] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Label] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Nullable] [bit] NOT NULL,
	[Enabled] [bit] NOT NULL,
	[Visible] [bit] NOT NULL,
	[DefaultValue] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsAlteration] [bit] NOT NULL,
	[ShowOnBrowseForm] [bit] NOT NULL,
	[MetaEntityExtensionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[MetaEntityExtensionFields]  WITH CHECK ADD  CONSTRAINT [EMetaEntityExtension_MetaEntityExtensionFields] FOREIGN KEY([MetaEntityExtensionId])
REFERENCES [dbo].[MetaEntityExtensions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[MetaEntityExtensionFields] CHECK CONSTRAINT [EMetaEntityExtension_MetaEntityExtensionFields]
GO
