CREATE TYPE [dbo].[CPUBaseStructure] AS TABLE(
	[IsAggregate] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsRegularPaymentStream] [bit] NOT NULL,
	[BaseAmount_Amount] [decimal](16, 2) NULL,
	[BaseAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BaseUnit] [int] NULL,
	[DistributionBasis] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[NumberofPayments] [int] NULL,
	[FrequencyStartDate] [date] NULL,
	[AssetPaymentScheduleUpload_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[AssetPaymentScheduleUpload_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[AssetPaymentScheduleUpload_Content] [varbinary](82) NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
