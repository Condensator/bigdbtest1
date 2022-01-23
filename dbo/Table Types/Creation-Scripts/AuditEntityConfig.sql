CREATE TYPE [dbo].[AuditEntityConfig] AS TABLE(
	[TableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserFriendlyName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[NaturalIdentifier] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[NaturalIdentifierLookupField] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[NaturalIdentifierLookupEntity] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsEnabled] [bit] NOT NULL,
	[QuerySource] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TextProperty] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[GridName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
