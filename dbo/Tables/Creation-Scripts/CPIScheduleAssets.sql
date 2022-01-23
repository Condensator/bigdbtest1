SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPIScheduleAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BeginDate] [date] NOT NULL,
	[BaseProcessThroughDate] [date] NULL,
	[OverageProcessThroughDate] [date] NULL,
	[BaseRate] [decimal](8, 4) NOT NULL,
	[BaseAmount_Amount] [decimal](16, 2) NOT NULL,
	[BaseAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BaseAllowance] [int] NOT NULL,
	[TerminationDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[CPIScheduleId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsPrimaryAsset] [bit] NOT NULL,
	[LastBaseRateUsed] [decimal](8, 4) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPIScheduleAssets]  WITH CHECK ADD  CONSTRAINT [ECPISchedule_CPIScheduleAssets] FOREIGN KEY([CPIScheduleId])
REFERENCES [dbo].[CPISchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPIScheduleAssets] CHECK CONSTRAINT [ECPISchedule_CPIScheduleAssets]
GO
ALTER TABLE [dbo].[CPIScheduleAssets]  WITH CHECK ADD  CONSTRAINT [ECPIScheduleAsset_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[CPIScheduleAssets] CHECK CONSTRAINT [ECPIScheduleAsset_Asset]
GO
