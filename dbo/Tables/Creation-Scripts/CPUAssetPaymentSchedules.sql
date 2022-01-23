SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUAssetPaymentSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Units] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[CPUPaymentScheduleId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[CPUBaseStructureId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUAssetPaymentSchedules]  WITH CHECK ADD  CONSTRAINT [ECPUAssetPaymentSchedule_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[CPUAssetPaymentSchedules] CHECK CONSTRAINT [ECPUAssetPaymentSchedule_Asset]
GO
ALTER TABLE [dbo].[CPUAssetPaymentSchedules]  WITH CHECK ADD  CONSTRAINT [ECPUAssetPaymentSchedule_CPUPaymentSchedule] FOREIGN KEY([CPUPaymentScheduleId])
REFERENCES [dbo].[CPUPaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[CPUAssetPaymentSchedules] CHECK CONSTRAINT [ECPUAssetPaymentSchedule_CPUPaymentSchedule]
GO
ALTER TABLE [dbo].[CPUAssetPaymentSchedules]  WITH CHECK ADD  CONSTRAINT [ECPUBaseStructure_CPUAssetPaymentSchedules] FOREIGN KEY([CPUBaseStructureId])
REFERENCES [dbo].[CPUBaseStructures] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUAssetPaymentSchedules] CHECK CONSTRAINT [ECPUBaseStructure_CPUAssetPaymentSchedules]
GO
