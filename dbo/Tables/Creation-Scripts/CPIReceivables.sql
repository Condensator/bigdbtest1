SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPIReceivables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Type] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [date] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CPIMeterId] [bigint] NULL,
	[CPIScheduleId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PayableId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPIReceivables]  WITH CHECK ADD  CONSTRAINT [ECPIReceivable_CPIMeter] FOREIGN KEY([CPIMeterId])
REFERENCES [dbo].[CPIMeters] ([Id])
GO
ALTER TABLE [dbo].[CPIReceivables] CHECK CONSTRAINT [ECPIReceivable_CPIMeter]
GO
ALTER TABLE [dbo].[CPIReceivables]  WITH CHECK ADD  CONSTRAINT [ECPIReceivable_Payable] FOREIGN KEY([PayableId])
REFERENCES [dbo].[Payables] ([Id])
GO
ALTER TABLE [dbo].[CPIReceivables] CHECK CONSTRAINT [ECPIReceivable_Payable]
GO
ALTER TABLE [dbo].[CPIReceivables]  WITH CHECK ADD  CONSTRAINT [ECPISchedule_CPIReceivables] FOREIGN KEY([CPIScheduleId])
REFERENCES [dbo].[CPISchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPIReceivables] CHECK CONSTRAINT [ECPISchedule_CPIReceivables]
GO
