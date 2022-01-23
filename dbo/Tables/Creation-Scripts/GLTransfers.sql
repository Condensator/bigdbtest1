SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLTransfers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[GLTransferType] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[HoldingStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NOT NULL,
	[Status] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsGLExportRequired] [bit] NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[MovePLBalance] [bit] NOT NULL,
	[PLEffectiveDate] [date] NULL,
	[IsFromUI] [bit] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[NonDateSensitive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLTransfers]  WITH CHECK ADD  CONSTRAINT [EGLTransfer_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[GLTransfers] CHECK CONSTRAINT [EGLTransfer_BusinessUnit]
GO
ALTER TABLE [dbo].[GLTransfers]  WITH CHECK ADD  CONSTRAINT [EGLTransfer_JobStepInstance] FOREIGN KEY([JobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[GLTransfers] CHECK CONSTRAINT [EGLTransfer_JobStepInstance]
GO
