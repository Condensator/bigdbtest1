SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BusinessCalendarDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BusinessDate] [date] NOT NULL,
	[IsWeekday] [bit] NOT NULL,
	[IsHoliday] [bit] NOT NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BusinessCalendarId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BusinessCalendarDetails]  WITH CHECK ADD  CONSTRAINT [EBusinessCalendarDetail_BusinessCalendar] FOREIGN KEY([BusinessCalendarId])
REFERENCES [dbo].[BusinessCalendars] ([Id])
GO
ALTER TABLE [dbo].[BusinessCalendarDetails] CHECK CONSTRAINT [EBusinessCalendarDetail_BusinessCalendar]
GO
