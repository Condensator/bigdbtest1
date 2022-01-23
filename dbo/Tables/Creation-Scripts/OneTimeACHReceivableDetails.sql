SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OneTimeACHReceivableDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxApplied_Amount] [decimal](16, 2) NOT NULL,
	[TaxApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[OneTimeACHScheduleId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[OneTimeACHReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHReceivableDetail_ReceivableDetail] FOREIGN KEY([ReceivableDetailId])
REFERENCES [dbo].[ReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHReceivableDetails] CHECK CONSTRAINT [EOneTimeACHReceivableDetail_ReceivableDetail]
GO
ALTER TABLE [dbo].[OneTimeACHReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EOneTimeACHSchedule_OneTimeACHReceivableDetails] FOREIGN KEY([OneTimeACHScheduleId])
REFERENCES [dbo].[OneTimeACHSchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OneTimeACHReceivableDetails] CHECK CONSTRAINT [EOneTimeACHSchedule_OneTimeACHReceivableDetails]
GO
