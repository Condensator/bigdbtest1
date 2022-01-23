SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OneTimeACHReceivables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableId] [bigint] NOT NULL,
	[OneTimeACHId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Status] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmountApplied_Amount] [decimal](16, 2) NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OneTimeACHReceivables]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_OneTimeACHReceivables] FOREIGN KEY([OneTimeACHId])
REFERENCES [dbo].[OneTimeACHes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OneTimeACHReceivables] CHECK CONSTRAINT [EOneTimeACH_OneTimeACHReceivables]
GO
ALTER TABLE [dbo].[OneTimeACHReceivables]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHReceivable_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHReceivables] CHECK CONSTRAINT [EOneTimeACHReceivable_Receivable]
GO
