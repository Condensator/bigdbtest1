CREATE TYPE [dbo].[CreditSNCHistory] AS TABLE(
	[IsSNCCode] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SNCRating] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[SNCRole] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[SNCAgent] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[SNCRatingDate] [date] NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
