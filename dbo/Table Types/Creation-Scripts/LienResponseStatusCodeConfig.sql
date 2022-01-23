CREATE TYPE [dbo].[LienResponseStatusCodeConfig] AS TABLE(
	[StatusCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExternalRecordStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[AuthorityFilingStatus] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
