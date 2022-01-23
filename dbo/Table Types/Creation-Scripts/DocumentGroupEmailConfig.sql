CREATE TYPE [dbo].[DocumentGroupEmailConfig] AS TABLE(
	[FromEmailExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[ToEmailConfigId] [bigint] NOT NULL,
	[CcEmailConfigId] [bigint] NULL,
	[BccEmailConfigId] [bigint] NULL,
	[EmailTemplateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
