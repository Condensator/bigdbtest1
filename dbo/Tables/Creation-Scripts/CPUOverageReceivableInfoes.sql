SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUOverageReceivableInfoes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CPUOverageReceivableGroupInfoId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUOverageReceivableInfoes]  WITH CHECK ADD  CONSTRAINT [ECPUOverageReceivableGroupInfo_CPUOverageReceivableInfoes] FOREIGN KEY([CPUOverageReceivableGroupInfoId])
REFERENCES [dbo].[CPUOverageReceivableGroupInfoes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUOverageReceivableInfoes] CHECK CONSTRAINT [ECPUOverageReceivableGroupInfo_CPUOverageReceivableInfoes]
GO
ALTER TABLE [dbo].[CPUOverageReceivableInfoes]  WITH CHECK ADD  CONSTRAINT [ECPUOverageReceivableInfo_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[CPUOverageReceivableInfoes] CHECK CONSTRAINT [ECPUOverageReceivableInfo_Receivable]
GO
