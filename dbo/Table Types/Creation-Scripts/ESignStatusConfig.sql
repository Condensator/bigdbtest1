CREATE TYPE [dbo].[ESignStatusConfig] AS TABLE(
	[ESignSystem] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ThirdPartyStatus] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[InternalStatus] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Level] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
