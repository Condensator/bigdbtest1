CREATE TYPE [dbo].[Discounting] AS TABLE(
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[NonAccrualDate] [date] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
