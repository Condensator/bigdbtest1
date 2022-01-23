CREATE TYPE [dbo].[LienResponse] AS TABLE(
	[ExternalSystemNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ExternalRecordStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[AuthorityFilingStatus] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[AuthoritySubmitDate] [date] NULL,
	[AuthorityFileNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AuthorityFileDate] [date] NULL,
	[AuthorityOriginalFileDate] [date] NULL,
	[AuthorityFileExpiryDate] [date] NULL,
	[AuthorityFilingOffice] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AuthorityFilingType] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[ReasonReport_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ReasonReport_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[ReasonReport_Content] [varbinary](82) NULL,
	[AuthorityFilingStateId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
