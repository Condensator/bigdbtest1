SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeasePreclassificationResults](
	[Id] [bigint] NOT NULL,
	[ContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NinetyPercentTestPresentValue5A_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue5A_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NinetyPercentTestPresentValue5B_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue5B_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreClassificationYield5A] [decimal](28, 18) NOT NULL,
	[PreClassificationYield5B] [decimal](28, 18) NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[NinetyPercentTestPresentValue_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreRVINinetyPercentTestPresentValue_Amount] [decimal](16, 2) NOT NULL,
	[PreRVINinetyPercentTestPresentValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreClassificationYield] [decimal](28, 18) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeasePreclassificationResults]  WITH CHECK ADD  CONSTRAINT [ELeaseAsset_LeasePreclassificationResult] FOREIGN KEY([Id])
REFERENCES [dbo].[LeaseAssets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeasePreclassificationResults] CHECK CONSTRAINT [ELeaseAsset_LeasePreclassificationResult]
GO
