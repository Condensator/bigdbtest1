CREATE TYPE [dbo].[CustomerServiceOrWorkout] AS TABLE(
	[CreditWatch] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Date] [date] NULL,
	[Reason] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CustomerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
