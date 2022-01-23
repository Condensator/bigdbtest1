CREATE TYPE [dbo].[CollectionWorkList] AS TABLE(
	[Status] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssignmentMethod] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[FlagAsWorked] [bit] NOT NULL,
	[NextWorkDate] [date] NULL,
	[FlagAsWorkedOn] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[PrimaryCollectorId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
	[CollectionQueueId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RemitToId] [bigint] NULL,
	[BusinessUnitId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
