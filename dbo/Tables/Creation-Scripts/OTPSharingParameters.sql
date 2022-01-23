SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OTPSharingParameters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[OTPSharingPercentage] [decimal](18, 8) NOT NULL,
	[PaymentNumber] [int] NOT NULL,
	[OTPSharingTemplateId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
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
ALTER TABLE [dbo].[OTPSharingParameters]  WITH CHECK ADD  CONSTRAINT [EOTPSharingTemplate_OTPSharingParameters] FOREIGN KEY([OTPSharingTemplateId])
REFERENCES [dbo].[OTPSharingTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OTPSharingParameters] CHECK CONSTRAINT [EOTPSharingTemplate_OTPSharingParameters]
GO
