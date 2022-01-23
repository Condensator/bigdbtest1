CREATE TYPE [dbo].[TimeZone] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Zone] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[Abbreviation] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[StandardZoneId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
