CREATE TYPE [dbo].[EnmasseMeterReadingInput] AS TABLE(
	[CPINumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SerialNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MeterType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EndPeriodDate] [date] NULL,
	[ReadDate] [date] NULL,
	[BeginReading] [bigint] NULL,
	[EndReading] [bigint] NULL,
	[ServiceCredits] [bigint] NOT NULL,
	[Source] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsEstimated] [bit] NOT NULL,
	[MeterResetType] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[InstanceId] [uniqueidentifier] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
