SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivablesToGlPosting_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsReceivableGLPosted] [bit] NOT NULL,
	[ReceivableTaxId] [bigint] NOT NULL,
	[IsTaxGLPosted] [bit] NOT NULL,
	[InvoiceRunDate] [date] NOT NULL,
	[ReceivableTaxType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[IsGLProcessed] [bit] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
