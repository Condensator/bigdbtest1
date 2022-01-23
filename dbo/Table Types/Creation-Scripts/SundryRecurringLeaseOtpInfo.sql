CREATE TYPE [dbo].[SundryRecurringLeaseOtpInfo] AS TABLE(
	[SundryRecurringId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MaturityDate] [date] NULL,
	[LastExtensionARUpdateRunDate] [date] NULL,
	[LastSupplementalARUpdateRunDate] [date] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
