CREATE TYPE [dbo].[CreditBureauRqstConsumerTradeLine] AS TABLE(
	[SourceSegment] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AccountDesignatorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AccountType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DateOpened] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CurrentStatus] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreditBureauRqstConsumerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
