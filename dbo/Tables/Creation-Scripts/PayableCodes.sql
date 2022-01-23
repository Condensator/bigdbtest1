SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayableCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[DefaultComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayableTypeId] [bigint] NOT NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayableCodes]  WITH CHECK ADD  CONSTRAINT [EPayableCode_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[PayableCodes] CHECK CONSTRAINT [EPayableCode_GLTemplate]
GO
ALTER TABLE [dbo].[PayableCodes]  WITH CHECK ADD  CONSTRAINT [EPayableCode_PayableType] FOREIGN KEY([PayableTypeId])
REFERENCES [dbo].[PayableTypes] ([Id])
GO
ALTER TABLE [dbo].[PayableCodes] CHECK CONSTRAINT [EPayableCode_PayableType]
GO
ALTER TABLE [dbo].[PayableCodes]  WITH CHECK ADD  CONSTRAINT [EPayableCode_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[PayableCodes] CHECK CONSTRAINT [EPayableCode_Portfolio]
GO
