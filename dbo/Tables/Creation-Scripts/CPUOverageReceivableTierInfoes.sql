SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUOverageReceivableTierInfoes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BeginUnit] [int] NOT NULL,
	[EndUnit] [int] NOT NULL,
	[Rate] [decimal](14, 9) NOT NULL,
	[CPUOverageReceivableInfoId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[CPUOverageReceivableTierInfoes]  WITH CHECK ADD  CONSTRAINT [ECPUOverageReceivableInfo_CPUOverageReceivableTierInfoes] FOREIGN KEY([CPUOverageReceivableInfoId])
REFERENCES [dbo].[CPUOverageReceivableInfoes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUOverageReceivableTierInfoes] CHECK CONSTRAINT [ECPUOverageReceivableInfo_CPUOverageReceivableTierInfoes]
GO
