CREATE TYPE [dbo].[DocumentStatusHistory] AS TABLE(
	[RowNumber] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AsOfDate] [date] NOT NULL,
	[Comment] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[StatusId] [bigint] NOT NULL,
	[StatusChangedById] [bigint] NOT NULL,
	[DocumentInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
