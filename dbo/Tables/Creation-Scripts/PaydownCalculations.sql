SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaydownCalculations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UseExpression] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaydownTemplateId] [bigint] NOT NULL,
	[PayoffTerminationExpressionId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PaydownCalculations]  WITH CHECK ADD  CONSTRAINT [EPaydownCalculation_PayoffTerminationExpression] FOREIGN KEY([PayoffTerminationExpressionId])
REFERENCES [dbo].[PayoffTerminationExpressions] ([Id])
GO
ALTER TABLE [dbo].[PaydownCalculations] CHECK CONSTRAINT [EPaydownCalculation_PayoffTerminationExpression]
GO
ALTER TABLE [dbo].[PaydownCalculations]  WITH CHECK ADD  CONSTRAINT [EPaydownTemplate_PaydownCalculations] FOREIGN KEY([PaydownTemplateId])
REFERENCES [dbo].[Paydowntemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PaydownCalculations] CHECK CONSTRAINT [EPaydownTemplate_PaydownCalculations]
GO
