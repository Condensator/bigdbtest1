CREATE TYPE [dbo].[AuthorityType] AS TABLE(
	[SystemDefinedName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Category] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Entity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Attribute] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Expression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Qualfier] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
