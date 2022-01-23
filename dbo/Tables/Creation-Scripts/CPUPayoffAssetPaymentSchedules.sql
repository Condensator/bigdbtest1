SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUPayoffAssetPaymentSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BaseAmount_Amount] [decimal](16, 2) NOT NULL,
	[BaseAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BaseUnits] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[CPUPayoffScheduleId] [bigint] NOT NULL,
	[CPUPayoffPaymentScheduleId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUPayoffAssetPaymentSchedules]  WITH CHECK ADD  CONSTRAINT [ECPUPayoffAssetPaymentSchedule_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[CPUPayoffAssetPaymentSchedules] CHECK CONSTRAINT [ECPUPayoffAssetPaymentSchedule_Asset]
GO
ALTER TABLE [dbo].[CPUPayoffAssetPaymentSchedules]  WITH CHECK ADD  CONSTRAINT [ECPUPayoffAssetPaymentSchedule_CPUPayoffPaymentSchedule] FOREIGN KEY([CPUPayoffPaymentScheduleId])
REFERENCES [dbo].[CPUPayoffPaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[CPUPayoffAssetPaymentSchedules] CHECK CONSTRAINT [ECPUPayoffAssetPaymentSchedule_CPUPayoffPaymentSchedule]
GO
ALTER TABLE [dbo].[CPUPayoffAssetPaymentSchedules]  WITH CHECK ADD  CONSTRAINT [ECPUPayoffSchedule_CPUPayoffAssetPaymentSchedules] FOREIGN KEY([CPUPayoffScheduleId])
REFERENCES [dbo].[CPUPayoffSchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUPayoffAssetPaymentSchedules] CHECK CONSTRAINT [ECPUPayoffSchedule_CPUPayoffAssetPaymentSchedules]
GO
