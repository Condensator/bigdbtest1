SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GenericExtractionConfigurations](
	[Id] [bigint] NOT NULL,
	[IsHeaderRequired] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomHeaderData] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[FileNameFormat] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[FileExtension] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomFileExtension] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[IsTriggerFileRequired] [bit] NOT NULL,
	[TriggerFileName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[FileSplitThreshold] [int] NULL,
	[Delimiter] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[FilePath] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[UseFieldEnclosure] [bit] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CreateSubFolderPerDataSet] [bit] NOT NULL,
	[MessageNotificationComponent] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GenericExtractionConfigurations]  WITH CHECK ADD  CONSTRAINT [EQueryProfile_GenericExtractionConfiguration] FOREIGN KEY([Id])
REFERENCES [dbo].[QueryProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GenericExtractionConfigurations] CHECK CONSTRAINT [EQueryProfile_GenericExtractionConfiguration]
GO
