SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EnmasseMeterReadingHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CPINumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SerialNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MeterType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EndPeriodDate] [date] NULL,
	[ReadDate] [date] NULL,
	[BeginReading] [bigint] NULL,
	[EndReading] [bigint] NULL,
	[ServiceCredits] [bigint] NOT NULL,
	[Source] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsEstimated] [bit] NOT NULL,
	[MeterResetType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InstanceId] [uniqueidentifier] NULL,
	[RowId] [bigint] NULL,
	[EnmasseMeterReadingInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
