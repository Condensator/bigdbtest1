CREATE TYPE [dbo].[GenericExtractionConfiguration] AS TABLE(
	[IsHeaderRequired] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
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
	[CreateSubFolderPerDataSet] [bit] NOT NULL,
	[MessageNotificationComponent] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
