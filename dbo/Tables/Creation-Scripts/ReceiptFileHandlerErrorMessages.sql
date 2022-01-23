SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptFileHandlerErrorMessages](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RowId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ErrorMessage] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[SourceTable] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptFileHandlerErrorMessages]  WITH CHECK ADD  CONSTRAINT [EReceiptFileHandlerErrorMessage_JobStepInstance] FOREIGN KEY([JobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[ReceiptFileHandlerErrorMessages] CHECK CONSTRAINT [EReceiptFileHandlerErrorMessage_JobStepInstance]
GO
