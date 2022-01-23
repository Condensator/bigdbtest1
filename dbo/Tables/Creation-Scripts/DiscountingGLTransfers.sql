SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingGLTransfers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLTransferType] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[Status] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[IsGLExportRequired] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingGLTransfers]  WITH CHECK ADD  CONSTRAINT [EDiscountingGLTransfer_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[DiscountingGLTransfers] CHECK CONSTRAINT [EDiscountingGLTransfer_BusinessUnit]
GO
ALTER TABLE [dbo].[DiscountingGLTransfers]  WITH CHECK ADD  CONSTRAINT [EDiscountingGLTransfer_JobStepInstance] FOREIGN KEY([JobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[DiscountingGLTransfers] CHECK CONSTRAINT [EDiscountingGLTransfer_JobStepInstance]
GO
