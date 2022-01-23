CREATE TYPE [dbo].[BusinessCalendarDetail] AS TABLE(
	[BusinessDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsWeekday] [bit] NOT NULL,
	[IsHoliday] [bit] NOT NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[BusinessCalendarId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
