SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AuditEntityConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[UserFriendlyName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[NaturalIdentifier] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsEnabled] [bit] NOT NULL,
	[NaturalIdentifierLookupField] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[NaturalIdentifierLookupEntity] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[QuerySource] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TextProperty] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[GridName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
