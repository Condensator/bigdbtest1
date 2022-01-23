CREATE TYPE [dbo].[FiscalCalendar] AS TABLE(
	[FiscalEndDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CalendarEndDate] [date] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[BusinessCalendarId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
