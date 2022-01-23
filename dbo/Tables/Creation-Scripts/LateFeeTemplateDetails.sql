SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LateFeeTemplateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DaysLate] [int] NOT NULL,
	[FlatFeeAmount_Amount] [decimal](16, 2) NULL,
	[FlatFeeAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PayPercent] [decimal](10, 6) NULL,
	[InterestRate] [decimal](10, 6) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LateFeeTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LateFeeTemplateDetails]  WITH CHECK ADD  CONSTRAINT [ELateFeeTemplate_LateFeeTemplateDetails] FOREIGN KEY([LateFeeTemplateId])
REFERENCES [dbo].[LateFeeTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LateFeeTemplateDetails] CHECK CONSTRAINT [ELateFeeTemplate_LateFeeTemplateDetails]
GO
