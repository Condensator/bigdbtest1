CREATE TYPE [dbo].[ESignEnvelopeHistory] AS TABLE(
	[Date] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Activity] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Name] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExternalId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ESignEnvelopeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
