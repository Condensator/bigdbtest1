SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BulkUploadSteps](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Type] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Entity] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Transaction] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ProcessingOrder] [decimal](16, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ScenarioConfigId] [bigint] NULL,
	[BulkUploadProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BulkUploadSteps]  WITH CHECK ADD  CONSTRAINT [EBulkUploadProfile_BulkUploadSteps] FOREIGN KEY([BulkUploadProfileId])
REFERENCES [dbo].[BulkUploadProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[BulkUploadSteps] CHECK CONSTRAINT [EBulkUploadProfile_BulkUploadSteps]
GO
ALTER TABLE [dbo].[BulkUploadSteps]  WITH CHECK ADD  CONSTRAINT [EBulkUploadStep_ScenarioConfig] FOREIGN KEY([ScenarioConfigId])
REFERENCES [dbo].[ScenarioConfigs] ([Id])
GO
ALTER TABLE [dbo].[BulkUploadSteps] CHECK CONSTRAINT [EBulkUploadStep_ScenarioConfig]
GO
