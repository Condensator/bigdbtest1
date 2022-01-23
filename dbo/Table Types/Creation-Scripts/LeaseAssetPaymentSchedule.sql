CREATE TYPE [dbo].[LeaseAssetPaymentSchedule] AS TABLE(
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InstallationDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableAdjustmentAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableAdjustmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[LeasePaymentScheduleId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
