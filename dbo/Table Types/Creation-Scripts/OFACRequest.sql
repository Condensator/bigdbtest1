CREATE TYPE [dbo].[OFACRequest] AS TABLE(
	[RequestType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RequestDate] [date] NULL,
	[ResponseDate] [date] NULL,
	[ResponseType] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[RequestXml] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ResponseXml] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[PartyId] [bigint] NULL,
	[PartyContactId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
