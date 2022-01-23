SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUBasePaymentEscalations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StepPeriod] [int] NOT NULL,
	[EscalationMethod] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Percentage] [decimal](5, 2) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsCreatedFromBooking] [bit] NOT NULL,
	[CPUBaseStructureId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUBasePaymentEscalations]  WITH CHECK ADD  CONSTRAINT [ECPUBaseStructure_CPUBasePaymentEscalations] FOREIGN KEY([CPUBaseStructureId])
REFERENCES [dbo].[CPUBaseStructures] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUBasePaymentEscalations] CHECK CONSTRAINT [ECPUBaseStructure_CPUBasePaymentEscalations]
GO
