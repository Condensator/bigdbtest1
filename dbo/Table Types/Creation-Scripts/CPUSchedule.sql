CREATE TYPE [dbo].[CPUSchedule] AS TABLE(
	[ScheduleNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CommencementDate] [date] NOT NULL,
	[EstimationMethod] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PayoffDate] [date] NULL,
	[IsBasePaymentScheduleGenerationRequired] [bit] NOT NULL,
	[IsOverageTierScheduleGenerationRequired] [bit] NOT NULL,
	[BaseJobRanForCompletion] [bit] NOT NULL,
	[IsCreatedFromBooking] [bit] NOT NULL,
	[MeterTypeId] [bigint] NOT NULL,
	[CPUFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
