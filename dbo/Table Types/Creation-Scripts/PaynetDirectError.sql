CREATE TYPE [dbo].[PaynetDirectError] AS TABLE(
	[ErrorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[LoggedDate] [date] NULL,
	[User] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsFromWorkFlow] [bit] NOT NULL,
	[ResponseName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PaynetDirectDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
