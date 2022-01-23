SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUPaymentSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentNumber] [int] NOT NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [date] NOT NULL,
	[DueDate] [date] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Units] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[CPUBaseStructureId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PaymentType] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUPaymentSchedules]  WITH CHECK ADD  CONSTRAINT [ECPUBaseStructure_CPUPaymentSchedules] FOREIGN KEY([CPUBaseStructureId])
REFERENCES [dbo].[CPUBaseStructures] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUPaymentSchedules] CHECK CONSTRAINT [ECPUBaseStructure_CPUPaymentSchedules]
GO
