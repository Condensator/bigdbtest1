CREATE TYPE [dbo].[ScenarioConfig] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[XamlFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[XamlFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[XamlFile_Content] [varbinary](82) NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
