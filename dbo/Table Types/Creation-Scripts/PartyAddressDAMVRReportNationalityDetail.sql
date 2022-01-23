CREATE TYPE [dbo].[PartyAddressDAMVRReportNationalityDetail] AS TABLE(
	[NationalityCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NationalityName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NationalityNameLatin] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PartyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
