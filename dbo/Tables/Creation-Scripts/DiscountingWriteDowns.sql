SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingWriteDowns](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[WriteDownDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[WriteDownAmount_Amount] [decimal](16, 2) NULL,
	[WriteDownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsRecovery] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[GrossWriteDown_Amount] [decimal](16, 2) NULL,
	[GrossWriteDown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NBVPostAdjustments_Amount] [decimal](16, 2) NULL,
	[NBVPostAdjustments_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NetWriteDown_Amount] [decimal](16, 2) NULL,
	[NetWriteDown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Status] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[NetInvestmentWithReserve_Amount] [decimal](16, 2) NULL,
	[NetInvestmentWithReserve_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[SourceId] [bigint] NOT NULL,
	[SourceModule] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[DiscountingId] [bigint] NOT NULL,
	[RecoveryGLTemplateId] [bigint] NOT NULL,
	[WriteDownGLTemplateId] [bigint] NULL,
	[DiscountingFinanceId] [bigint] NULL,
	[DiscountingWriteDownGLJournalId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingWriteDowns]  WITH CHECK ADD  CONSTRAINT [EDiscountingWriteDown_Discounting] FOREIGN KEY([DiscountingId])
REFERENCES [dbo].[Discountings] ([Id])
GO
ALTER TABLE [dbo].[DiscountingWriteDowns] CHECK CONSTRAINT [EDiscountingWriteDown_Discounting]
GO
ALTER TABLE [dbo].[DiscountingWriteDowns]  WITH CHECK ADD  CONSTRAINT [EDiscountingWriteDown_DiscountingFinance] FOREIGN KEY([DiscountingFinanceId])
REFERENCES [dbo].[DiscountingFinances] ([Id])
GO
ALTER TABLE [dbo].[DiscountingWriteDowns] CHECK CONSTRAINT [EDiscountingWriteDown_DiscountingFinance]
GO
ALTER TABLE [dbo].[DiscountingWriteDowns]  WITH CHECK ADD  CONSTRAINT [EDiscountingWriteDown_DiscountingWriteDownGLJournal] FOREIGN KEY([DiscountingWriteDownGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[DiscountingWriteDowns] CHECK CONSTRAINT [EDiscountingWriteDown_DiscountingWriteDownGLJournal]
GO
ALTER TABLE [dbo].[DiscountingWriteDowns]  WITH CHECK ADD  CONSTRAINT [EDiscountingWriteDown_RecoveryGLTemplate] FOREIGN KEY([RecoveryGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[DiscountingWriteDowns] CHECK CONSTRAINT [EDiscountingWriteDown_RecoveryGLTemplate]
GO
ALTER TABLE [dbo].[DiscountingWriteDowns]  WITH CHECK ADD  CONSTRAINT [EDiscountingWriteDown_WriteDownGLTemplate] FOREIGN KEY([WriteDownGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[DiscountingWriteDowns] CHECK CONSTRAINT [EDiscountingWriteDown_WriteDownGLTemplate]
GO
