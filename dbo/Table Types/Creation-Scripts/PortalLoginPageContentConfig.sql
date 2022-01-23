CREATE TYPE [dbo].[PortalLoginPageContentConfig] AS TABLE(
	[Description] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContactMessage_HTMLContent] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[EmailContact] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[SubSystemConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
