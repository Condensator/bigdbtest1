CREATE TYPE [dbo].[OFACHit] AS TABLE(
	[HitValue] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Status] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[DecisionTime] [date] NULL,
	[DecisionByUserId] [bigint] NULL,
	[OFACRequestId] [bigint] NULL,
	[PartyId] [bigint] NULL,
	[PartyContactId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
