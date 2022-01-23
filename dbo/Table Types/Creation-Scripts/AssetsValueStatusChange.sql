CREATE TYPE [dbo].[AssetsValueStatusChange] AS TABLE(
	[PostDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReversalPostDate] [date] NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Reason] [nvarchar](22) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsZeroMode] [bit] NOT NULL,
	[SourceModule] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[SourceModuleId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[MigrationId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
