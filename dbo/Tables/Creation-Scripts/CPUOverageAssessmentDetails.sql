SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUOverageAssessmentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MeterReadingId] [bigint] NOT NULL,
	[ReceivableId] [bigint] NULL,
	[CPUOverageAssessmentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUOverageAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [ECPUOverageAssessment_CPUOverageAssessmentDetails] FOREIGN KEY([CPUOverageAssessmentId])
REFERENCES [dbo].[CPUOverageAssessments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUOverageAssessmentDetails] CHECK CONSTRAINT [ECPUOverageAssessment_CPUOverageAssessmentDetails]
GO
ALTER TABLE [dbo].[CPUOverageAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [ECPUOverageAssessmentDetail_MeterReading] FOREIGN KEY([MeterReadingId])
REFERENCES [dbo].[CPUAssetMeterReadings] ([Id])
GO
ALTER TABLE [dbo].[CPUOverageAssessmentDetails] CHECK CONSTRAINT [ECPUOverageAssessmentDetail_MeterReading]
GO
ALTER TABLE [dbo].[CPUOverageAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [ECPUOverageAssessmentDetail_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[CPUOverageAssessmentDetails] CHECK CONSTRAINT [ECPUOverageAssessmentDetail_Receivable]
GO
