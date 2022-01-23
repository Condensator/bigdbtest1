CREATE TYPE [dbo].[CreditBureauError] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ErrorLevel] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[LoggedDate] [date] NULL,
	[User] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsFromWorkFlow] [bit] NOT NULL,
	[Source] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FICOErrorMessageConfigId] [bigint] NULL,
	[CreditBureauRequestId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
