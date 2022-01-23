SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobSchedules](
	[Id] [bigint] NOT NULL,
	[Frequency] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[RepeatDaily] [int] NULL,
	[IsMonday] [bit] NOT NULL,
	[IsTuesday] [bit] NOT NULL,
	[IsWednesday] [bit] NOT NULL,
	[IsThursday] [bit] NOT NULL,
	[IsFriday] [bit] NOT NULL,
	[IsSaturday] [bit] NOT NULL,
	[IsSunday] [bit] NOT NULL,
	[MonthlyType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[RepeatMonthly] [int] NULL,
	[DayOfMonth] [int] NULL,
	[DayOfWeekType] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[DayOfWeek] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[FrequencyType] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[Time] [datetimeoffset](7) NULL,
	[RepeatHours] [int] NULL,
	[RepeatMinutes] [int] NULL,
	[FromTime] [datetimeoffset](7) NULL,
	[ToTime] [datetimeoffset](7) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RunBetweenOption] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[JobSchedules]  WITH CHECK ADD  CONSTRAINT [EJob_JobSchedule] FOREIGN KEY([Id])
REFERENCES [dbo].[Jobs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[JobSchedules] CHECK CONSTRAINT [EJob_JobSchedule]
GO
