CREATE TYPE [dbo].[ReleaseVersion] AS TABLE(
	[VersionNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ShippedDate] [date] NOT NULL,
	[AppliedDate] [date] NOT NULL,
	[AppliedBy] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LatestDBScriptName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
