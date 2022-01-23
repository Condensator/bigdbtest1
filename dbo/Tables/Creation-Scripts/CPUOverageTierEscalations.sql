SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUOverageTierEscalations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StepPeriod] [int] NOT NULL,
	[EscalationMethod] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Percentage] [decimal](5, 2) NOT NULL,
	[Rate] [decimal](14, 9) NULL,
	[IsActive] [bit] NOT NULL,
	[OverageDecimalPlaces] [int] NOT NULL,
	[IsCreatedFromBooking] [bit] NOT NULL,
	[CPUOverageStructureId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUOverageTierEscalations]  WITH CHECK ADD  CONSTRAINT [ECPUOverageStructure_CPUOverageTierEscalations] FOREIGN KEY([CPUOverageStructureId])
REFERENCES [dbo].[CPUOverageStructures] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUOverageTierEscalations] CHECK CONSTRAINT [ECPUOverageStructure_CPUOverageTierEscalations]
GO
