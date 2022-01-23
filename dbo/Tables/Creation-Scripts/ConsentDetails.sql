SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConsentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveDate] [date] NULL,
	[ExpiryDate] [date] NULL,
	[ConsentStatus] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[ConsentCaptureMode] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[DocumentInstanceId] [bigint] NULL,
	[ConsentConfigId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[ConsentDetails]  WITH CHECK ADD  CONSTRAINT [EConsentDetail_ConsentConfig] FOREIGN KEY([ConsentConfigId])
REFERENCES [dbo].[ConsentConfigs] ([Id])
GO
ALTER TABLE [dbo].[ConsentDetails] CHECK CONSTRAINT [EConsentDetail_ConsentConfig]
GO
ALTER TABLE [dbo].[ConsentDetails]  WITH CHECK ADD  CONSTRAINT [EConsentDetail_DocumentInstance] FOREIGN KEY([DocumentInstanceId])
REFERENCES [dbo].[DocumentInstances] ([Id])
GO
ALTER TABLE [dbo].[ConsentDetails] CHECK CONSTRAINT [EConsentDetail_DocumentInstance]
GO
