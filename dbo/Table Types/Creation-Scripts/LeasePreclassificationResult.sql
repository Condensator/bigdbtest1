CREATE TYPE [dbo].[LeasePreclassificationResult] AS TABLE(
	[ContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PreClassificationYield5A] [decimal](28, 18) NOT NULL,
	[PreClassificationYield5B] [decimal](28, 18) NOT NULL,
	[PreClassificationYield] [decimal](28, 18) NOT NULL,
	[NinetyPercentTestPresentValue5A_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue5A_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NinetyPercentTestPresentValue5B_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue5B_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NinetyPercentTestPresentValue_Amount] [decimal](16, 2) NOT NULL,
	[NinetyPercentTestPresentValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreRVINinetyPercentTestPresentValue_Amount] [decimal](16, 2) NOT NULL,
	[PreRVINinetyPercentTestPresentValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
