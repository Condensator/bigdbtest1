CREATE TYPE [dbo].[DocumentEmail] AS TABLE(
	[ToEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CcEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[BccEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[FromEmailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[SentDate] [datetimeoffset](7) NOT NULL,
	[Status] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[StatusComment] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[RowNumber] [int] NOT NULL,
	[EmailTemplateId] [bigint] NULL,
	[SentByUserId] [bigint] NOT NULL,
	[DocumentHeaderId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
