CREATE TYPE [dbo].[ApiAsyncRequest] AS TABLE(
	[AcknowledgementId] [nvarchar](36) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RequestType] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[Payload] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [int] NULL,
	[ResponseMessage] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
