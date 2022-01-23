SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxDepAmortizationGLDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxDepAmortizationDetailId] [bigint] NOT NULL,
	[TaxDepAmortizationGLHeaderId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxDepAmortizationGLDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortizationGLDetail_TaxDepAmortizationDetail] FOREIGN KEY([TaxDepAmortizationDetailId])
REFERENCES [dbo].[TaxDepAmortizationDetails] ([Id])
GO
ALTER TABLE [dbo].[TaxDepAmortizationGLDetails] CHECK CONSTRAINT [ETaxDepAmortizationGLDetail_TaxDepAmortizationDetail]
GO
ALTER TABLE [dbo].[TaxDepAmortizationGLDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortizationGLHeader_TaxDepAmortizationGLDetails] FOREIGN KEY([TaxDepAmortizationGLHeaderId])
REFERENCES [dbo].[TaxDepAmortizationGLHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TaxDepAmortizationGLDetails] CHECK CONSTRAINT [ETaxDepAmortizationGLHeader_TaxDepAmortizationGLDetails]
GO
