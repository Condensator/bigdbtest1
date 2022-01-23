CREATE TYPE [dbo].[EmailNotification] AS TABLE(
	[FromEmailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Subject] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Body] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Content] [varbinary](82) NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
