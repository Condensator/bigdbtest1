SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FinancialStatementParameterAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Attachment_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Content] [varbinary](82) NOT NULL,
	[UploadedDate] [date] NOT NULL,
	[UploadedById] [bigint] NOT NULL,
	[FinancialStatementParameterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[FinancialStatementParameterAttachments]  WITH CHECK ADD  CONSTRAINT [EFinancialStatementParameter_FinancialStatementParameterAttachments] FOREIGN KEY([FinancialStatementParameterId])
REFERENCES [dbo].[FinancialStatementParameters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FinancialStatementParameterAttachments] CHECK CONSTRAINT [EFinancialStatementParameter_FinancialStatementParameterAttachments]
GO
ALTER TABLE [dbo].[FinancialStatementParameterAttachments]  WITH CHECK ADD  CONSTRAINT [EFinancialStatementParameterAttachment_UploadedBy] FOREIGN KEY([UploadedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[FinancialStatementParameterAttachments] CHECK CONSTRAINT [EFinancialStatementParameterAttachment_UploadedBy]
GO
