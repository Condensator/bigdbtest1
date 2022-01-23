SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertyTaxExportFileDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ExportFile] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsPreview] [bit] NOT NULL,
	[IsExported] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
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
ALTER TABLE [dbo].[PropertyTaxExportFileDetails]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxExportFileDetail_JobStepInstance] FOREIGN KEY([JobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxExportFileDetails] CHECK CONSTRAINT [EPropertyTaxExportFileDetail_JobStepInstance]
GO
