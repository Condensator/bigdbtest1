SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayableTypeInvoiceConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentType] [nvarchar](28) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ApplicableForTaxType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApplicableForBlending] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceLanguageLabel] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
