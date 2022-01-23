CREATE TYPE [dbo].[CollectionWorkListActivity] AS TABLE(
	[Number] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActivityDate] [date] NOT NULL,
	[ActivityId] [bigint] NOT NULL,
	[CollectionWorkListId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
