SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPIBaseStepRates](
	[Rate] [decimal](8, 4) NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StepPeriod] [int] NULL,
	[CPIReceivableDetailId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPIBaseStepRates]  WITH CHECK ADD  CONSTRAINT [ECPIBaseStepRate_CPIReceivableDetail] FOREIGN KEY([CPIReceivableDetailId])
REFERENCES [dbo].[CPIReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[CPIBaseStepRates] CHECK CONSTRAINT [ECPIBaseStepRate_CPIReceivableDetail]
GO
