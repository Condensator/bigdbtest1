CREATE TYPE [dbo].[CPUPayoffSchedule] AS TABLE(
	[IsFullPayoff] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ScheduleNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayoffDate] [date] NULL,
	[NumberofPayments] [int] NOT NULL,
	[BaseAmount_Amount] [decimal](16, 2) NOT NULL,
	[BaseAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BaseUnits] [int] NULL,
	[RefreshRequired] [bit] NOT NULL,
	[IsPaymentScheduleGenerationRequired] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CPUPayoffId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
