CREATE TYPE [dbo].[CPUOverageStructure] AS TABLE(
	[PaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FrequencyStartDate] [date] NULL,
	[OverageTier] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[NoOfPeriodsToAverage] [int] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
