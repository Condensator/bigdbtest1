CREATE TYPE [dbo].[PlanPayoutOptionVolumeTier] AS TABLE(
	[RowNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MinimumVolume_Amount] [decimal](16, 2) NOT NULL,
	[MinimumVolume_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[MaximumVolume_Amount] [decimal](16, 2) NOT NULL,
	[MaximumVolume_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Commission] [decimal](9, 5) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PlanBasesPayoutId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
