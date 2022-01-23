CREATE TYPE [dbo].[CPIScheduleAsset] AS TABLE(
	[BeginDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BaseProcessThroughDate] [date] NULL,
	[OverageProcessThroughDate] [date] NULL,
	[BaseRate] [decimal](8, 4) NOT NULL,
	[BaseAmount_Amount] [decimal](16, 2) NOT NULL,
	[BaseAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BaseAllowance] [int] NOT NULL,
	[TerminationDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[IsPrimaryAsset] [bit] NOT NULL,
	[LastBaseRateUsed] [decimal](8, 4) NULL,
	[AssetId] [bigint] NOT NULL,
	[CPIScheduleId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
