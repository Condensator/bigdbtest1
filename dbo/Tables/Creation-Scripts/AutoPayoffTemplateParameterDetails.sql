SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoPayoffTemplateParameterDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ParameterId] [bigint] NOT NULL,
	[AutoPayoffTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AutoPayoffTemplateParameterDetails]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplate_AutoPayoffTemplateParameterDetails] FOREIGN KEY([AutoPayoffTemplateId])
REFERENCES [dbo].[AutoPayoffTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AutoPayoffTemplateParameterDetails] CHECK CONSTRAINT [EAutoPayoffTemplate_AutoPayoffTemplateParameterDetails]
GO
ALTER TABLE [dbo].[AutoPayoffTemplateParameterDetails]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplateParameterDetail_Parameter] FOREIGN KEY([ParameterId])
REFERENCES [dbo].[AutoPayoffTemplateParameterConfigs] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffTemplateParameterDetails] CHECK CONSTRAINT [EAutoPayoffTemplateParameterDetail_Parameter]
GO
