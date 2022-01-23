SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BusinessUnits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CurrentBusinessDate] [date] NOT NULL,
	[ImplementCutoffTime] [bit] NOT NULL,
	[CutoffTimeThresholdInMins] [int] NOT NULL,
	[LatestNotifiedTime] [datetimeoffset](7) NULL,
	[LatestLoggedOutTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BusinessCalendarId] [bigint] NOT NULL,
	[StandardTimeZoneId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BusinessStartTimeInHours] [int] NOT NULL,
	[BusinessStartTimeInMinutes] [int] NOT NULL,
	[BusinessEndTimeInHours] [int] NOT NULL,
	[BusinessEndTimeInMinutes] [int] NOT NULL,
	[CutoffTimeInHours] [int] NULL,
	[CutoffTimeInMinutes] [int] NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BusinessUnits]  WITH CHECK ADD  CONSTRAINT [EBusinessUnit_BusinessCalendar] FOREIGN KEY([BusinessCalendarId])
REFERENCES [dbo].[BusinessCalendars] ([Id])
GO
ALTER TABLE [dbo].[BusinessUnits] CHECK CONSTRAINT [EBusinessUnit_BusinessCalendar]
GO
ALTER TABLE [dbo].[BusinessUnits]  WITH CHECK ADD  CONSTRAINT [EBusinessUnit_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[BusinessUnits] CHECK CONSTRAINT [EBusinessUnit_Portfolio]
GO
ALTER TABLE [dbo].[BusinessUnits]  WITH CHECK ADD  CONSTRAINT [EBusinessUnit_StandardTimeZone] FOREIGN KEY([StandardTimeZoneId])
REFERENCES [dbo].[TimeZones] ([Id])
GO
ALTER TABLE [dbo].[BusinessUnits] CHECK CONSTRAINT [EBusinessUnit_StandardTimeZone]
GO
