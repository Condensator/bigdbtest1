CREATE TYPE [dbo].[LicenseToken] AS TABLE(
	[UserId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CompanyName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[LoginAuditId] [bigint] NOT NULL,
	[Excluded] [bit] NOT NULL,
	[IsReadOnly] [bit] NOT NULL,
	[TokenKey] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
